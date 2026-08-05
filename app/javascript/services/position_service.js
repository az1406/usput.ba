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

export class PositionService {
  constructor() {
    this.subscribers = new Set()
    this.failureSubscribers = new Set()
    this.last = this.stored()
    this.#useDevPosition()
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

  // A fix the watcher actually produced this session, at any age. A remembered
  // position is a guess about where the device was last, not where it is.
  measured() {
    return this.fixedAt ? this.last : null
  }

  // Measured, recent, and not the coarse fallback. A wifi-derived fix orders a
  // deck honestly but is nowhere near good enough for a 100 m gate.
  fresh(maxAgeMs = 15000) {
    if (!this.fixedAt || this.coarse) return null
    return Date.now() - this.fixedAt <= maxAgeMs ? this.last : null
  }

  // Returns an unsubscribe. The watcher runs only while someone is listening.
  subscribe(callback, onFailure) {
    this.subscribers.add(callback)
    if (onFailure) this.failureSubscribers.add(onFailure)
    // Only a measured fix is worth acting on: a remembered one would relabel a
    // whole deck with distances from wherever the device was last.
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
    if (this.fixedAt || this.coarseInFlight) return
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
    this.coarse = coarse
    this.lastFailure = null
    this.persist()
    this.subscribers.forEach((callback) => callback(this.last))
  }

  persist() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(this.last))
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
