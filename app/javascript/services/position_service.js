// Position Service
// The only thing in the app that talks to navigator.geolocation. One watcher
// feeds the deck, the map and the check-in, so they can never disagree about
// where the traveller is or fight each other for a fix.

const STORAGE_KEY = "usput-last-position"
const WATCH_TIMEOUT_MS = 12000
const COARSE_TIMEOUT_MS = 8000
// A laptop has no GPS, so every fix is a network lookup. Reusing one the device
// already holds is the difference between instant and a round-trip.
const MAX_REUSE_MS = 60000
// The check-in gate is 100 m, so a fix whose own error bar is wider than that
// cannot decide it. A laptop reports wifi fixes in the hundreds or thousands.
const GATE_ACCURACY_M = 100
// Only long enough to bridge a provider stall, never long enough to be a
// different place: the explore deck freezes whatever it is first handed.
const REMEMBERED_MAX_AGE_MS = 120000

export class PositionService {
  constructor() {
    this.subscribers = new Set()
    this.failureSubscribers = new Set()
    this.#restore()
    this.#useDevPosition()
  }

  // Coarse always: it says where the device was, so it can never decide a gate.
  #restore() {
    const held = this.stored()
    if (!held) return

    this.last = held
    if (!held.at || Date.now() - held.at > REMEMBERED_MAX_AGE_MS) return
    this.fixedAt = held.at
    this.coarse = true
  }

  #useDevPosition() {
    const value = document.querySelector('meta[name="dev-position"]')?.content
    if (!value) return

    const [ latitude, longitude ] = value.split(",").map(Number)
    if (!isFinite(latitude) || !isFinite(longitude)) return

    this.pinned = true
    this.publish({ coords: { latitude, longitude, accuracy: 5 }, timestamp: Date.now() })
  }

  failure() {
    return this.lastFailure || null
  }

  // The freshest fix we hold, or the one this device ended on last time. Good
  // enough to order a deck or place a marker.
  current() {
    return this.last
  }

  // Measured this session, or remembered recently. Orients; never gates.
  measured() {
    return this.fixedAt ? this.last : null
  }

  // Measured, recent, and accurate enough to decide the gate. A wifi-derived
  // fix orders a deck honestly but is nowhere near good enough for 100 m.
  fresh(maxAgeMs = 15000) {
    if (!this.fixedAt || this.coarse) return null
    return Date.now() - this.fixedAt <= maxAgeMs ? this.last : null
  }

  // Returns an unsubscribe. The watcher runs only while someone is listening.
  subscribe(callback, onFailure) {
    this.subscribers.add(callback)
    if (onFailure) this.failureSubscribers.add(onFailure)
    const held = this.measured()
    if (held) callback(held)
    // start() will not re-ask a device that already failed.
    else if (this.lastFailure && onFailure) onFailure(this.lastFailure)
    this.start()

    return () => {
      this.subscribers.delete(callback)
      if (onFailure) this.failureSubscribers.delete(onFailure)
      if (this.subscribers.size === 0) this.stop()
    }
  }

  start() {
    if (this.pinned) return
    if (this.watchId !== undefined || !navigator.geolocation) return

    document.addEventListener("visibilitychange", this.onVisibility)
    this.seedCoarse()
    this.watch()
  }

  // A satellite fix can take a minute indoors or never arrive on a desktop; a
  // wifi one takes about a second and is enough to order a deck. Ask for both
  // and use whichever lands first. Guarded on in-flight rather than ever-ran:
  // this service outlives a page, so a once-only seed left every navigation
  // after the first waiting on the slow watcher alone.
  seedCoarse() {
    // Guarding on any fix let a coarse or restored one suppress its replacement.
    if ((this.fixedAt && !this.coarse) || this.coarseInFlight) return
    this.coarseInFlight = true
    navigator.geolocation.getCurrentPosition(
      (position) => {
        this.coarseInFlight = false
        if (!this.fixedAt || this.coarse) this.publish(position, { coarse: true })
      },
      () => { this.coarseInFlight = false },
      { enableHighAccuracy: false, timeout: COARSE_TIMEOUT_MS, maximumAge: MAX_REUSE_MS }
    )
  }

  watch() {
    if (this.watchId !== undefined) return
    this.watchId = navigator.geolocation.watchPosition(
      (position) => this.publish(position),
      (error) => this.reportFailure(error),
      // Without a timeout geolocation waits forever, and a device that can
      // never answer never calls back at all.
      { enableHighAccuracy: true, maximumAge: MAX_REUSE_MS, timeout: WATCH_TIMEOUT_MS }
    )
  }

  reportFailure(error) {
    if (error.code === error.PERMISSION_DENIED) this.clear()
    // Only a total absence of position is worth telling a surface about. The
    // accurate watcher timing out while the coarse seed already landed is the
    // expected case indoors, not a failure the traveller needs to see.
    if (this.fixedAt) return
    this.announceFailure(error)
  }

  announceFailure(error) {
    this.lastFailure = error
    this.failureSubscribers.forEach((callback) => callback(error))
  }

  stop() {
    document.removeEventListener("visibilitychange", this.onVisibility)
    this.clear()
  }

  clear() {
    if (this.watchId === undefined) return
    navigator.geolocation.clearWatch(this.watchId)
    this.watchId = undefined
  }

  // A backgrounded tab is not walking anywhere worth spending battery on.
  onVisibility = () => {
    if (document.hidden) return this.clear()
    if (this.subscribers.size > 0) this.watch()
  }

  // Age is taken from the device's own timestamp, not from when we happened to
  // receive it, so reusing a cached fix cannot make a stale one look recent.
  publish({ coords: { latitude, longitude, accuracy }, timestamp }, { coarse = false } = {}) {
    this.last = { latitude, longitude, accuracy }
    this.fixedAt = timestamp || Date.now()
    // The reading decides this, not the caller. The high-accuracy watcher
    // returns wifi-grade fixes on a laptop too, and a caller publishing one as
    // fine relabelled it for every surface that asks.
    this.coarse = coarse || !(accuracy <= GATE_ACCURACY_M)
    this.lastFailure = null
    this.persist()
    this.subscribers.forEach((callback) => callback(this.last))
  }

  persist() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify({ ...this.last, at: this.fixedAt }))
    } catch {
      // A full or blocked store is not worth failing a walk over.
    }
  }

  stored() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY)
      const parsed = raw ? JSON.parse(raw) : null
      return parsed?.latitude && parsed?.longitude ? parsed : null
    } catch {
      return null
    }
  }
}

export const positionService = new PositionService()
