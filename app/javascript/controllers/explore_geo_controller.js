import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "usput-last-position"

// Appends the visitor's coordinates to the category tile links so the deck
// deals nearest-first. A tap before the first fix is held rather than
// followed — without coordinates the server has no "nearest" to deal.
export default class extends Controller {
  static targets = ["tile"]

  connect() {
    this.located = this.applyStored()
    this.read()
  }

  hold(event) {
    if (this.located) return
    event.preventDefault()
    this.pendingTile = event.currentTarget
    this.pendingTile.setAttribute("aria-busy", "true")
  }

  read() {
    if (!navigator.geolocation) return this.release()
    navigator.geolocation.getCurrentPosition(
      (position) => {
        this.store(position.coords)
        this.applyCoords(position.coords)
        this.located = true
        this.release()
        this.handOff(position.coords)
      },
      () => this.release(),
      // Ordering by distance doesn't need a GPS lock, and maximumAge reuses a
      // recent fix so tiles usually carry coordinates before the first tap.
      { enableHighAccuracy: false, timeout: 5000, maximumAge: 60000 }
    )
  }

  // Entry has no category to pick any more — once we know where the traveller
  // is, the server decides which deck is closest and sends them there.
  handOff({ latitude, longitude }) {
    const url = new URL(window.location.href)
    if (url.searchParams.has("lat")) return
    url.searchParams.set("lat", latitude)
    url.searchParams.set("lng", longitude)
    window.location.replace(url.toString())
  }

  applyStored() {
    const stored = localStorage.getItem(STORAGE_KEY)
    if (!stored) return false
    try {
      const coords = JSON.parse(stored)
      this.applyCoords(coords)
      this.handOff(coords)
      return true
    } catch {
      localStorage.removeItem(STORAGE_KEY)
      return false
    }
  }

  store({ latitude, longitude }) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ latitude, longitude }))
  }

  applyCoords({ latitude, longitude }) {
    this.tileTargets.forEach((tile) => {
      const url = new URL(tile.href, window.location.origin)
      url.searchParams.set("lat", latitude)
      url.searchParams.set("lng", longitude)
      tile.href = url.toString()
    })
  }

  // Denied or unavailable still navigates — the deck page asks for location
  // itself rather than leaving the tap dead.
  release() {
    if (!this.pendingTile) return
    const tile = this.pendingTile
    this.pendingTile = null
    tile.removeAttribute("aria-busy")
    tile.click()
  }
}
