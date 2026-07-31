// Position Service
// The only thing in the app that talks to navigator.geolocation. One watcher
// feeds the deck, the map and the check-in, so they can never disagree about
// where the traveller is or fight each other for a fix.

const STORAGE_KEY = "usput-last-position"

export class PositionService {
  constructor() {
    this.subscribers = new Set()
    this.last = this.stored()
  }

  // The freshest fix we hold, or the one this device ended on last time. Good
  // enough to order a deck or place a marker.
  current() {
    return this.last
  }

  // A fix the watcher actually produced this session, at any age. A remembered
  // position is a guess about where the device was last, not where it is.
  measured() {
    return this.measuredAt ? this.last : null
  }

  // Measured and recent. A remembered position must never decide a 100 m gate.
  fresh(maxAgeMs = 15000) {
    if (!this.measuredAt) return null
    return performance.now() - this.measuredAt <= maxAgeMs ? this.last : null
  }

  // Returns an unsubscribe. The watcher runs only while someone is listening.
  subscribe(callback) {
    this.subscribers.add(callback)
    // Only a measured fix is worth acting on: a remembered one would relabel a
    // whole deck with distances from wherever the device was last.
    const held = this.measured()
    if (held) callback(held)
    this.start()

    return () => {
      this.subscribers.delete(callback)
      if (this.subscribers.size === 0) this.stop()
    }
  }

  start() {
    if (this.watchId !== undefined || !navigator.geolocation) return

    document.addEventListener("visibilitychange", this.onVisibility)
    this.watch()
  }

  watch() {
    if (this.watchId !== undefined) return
    this.watchId = navigator.geolocation.watchPosition(
      (position) => this.publish(position.coords),
      () => {},
      // A 100 m gate and a nearest-first deck both need a real fix, but a few
      // seconds of reuse keeps the radio idle between updates.
      { enableHighAccuracy: true, maximumAge: 5000 }
    )
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

  publish({ latitude, longitude }) {
    this.last = { latitude, longitude }
    this.measuredAt = performance.now()
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
