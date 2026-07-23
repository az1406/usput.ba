import { Controller } from "@hotwired/stimulus"

// Appends the visitor's coordinates to the category tile links so the deck
// deals nearest-first. Denied/unavailable geolocation leaves the links
// unchanged — the deck falls back to its own client-side nearest pick.
export default class extends Controller {
  static targets = ["tile"]

  connect() {
    if (!navigator.geolocation) return
    navigator.geolocation.getCurrentPosition(
      (position) => this.applyCoords(position.coords),
      () => {},
      { enableHighAccuracy: true, timeout: 8000 }
    )
  }

  applyCoords({ latitude, longitude }) {
    this.tileTargets.forEach((tile) => {
      const url = new URL(tile.href, window.location.origin)
      url.searchParams.set("lat", latitude)
      url.searchParams.set("lng", longitude)
      tile.href = url.toString()
    })
  }
}
