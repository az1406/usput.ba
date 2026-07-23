import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hint"]
  static values = { lat: Number, lng: Number }

  connect() {
    this.sending = false
    this.element.addEventListener("submit", this.capture)
  }

  disconnect() {
    this.element.removeEventListener("submit", this.capture)
  }

  capture = (event) => {
    if (this.sending) return
    event.preventDefault()

    if (!navigator.geolocation) return this.submitWith(0, 0)
    navigator.geolocation.getCurrentPosition(
      (position) => this.evaluate(position.coords.latitude, position.coords.longitude),
      () => this.submitWith(0, 0),
      { enableHighAccuracy: true, timeout: 10000 }
    )
  }

  evaluate(lat, lng) {
    const distanceKm = this.distance(lat, lng, this.latValue, this.lngValue)
    if (distanceKm <= 0.1) return this.submitWith(lat, lng)
    this.showHint(distanceKm, this.bearing(lat, lng, this.latValue, this.lngValue))
  }

  submitWith(lat, lng) {
    const form = this.element.querySelector("form")
    form.querySelector('input[name="user_lat"]').value = lat
    form.querySelector('input[name="user_lng"]').value = lng
    this.sending = true
    form.requestSubmit()
  }

  showHint(distanceKm, direction) {
    if (!this.hasHintTarget) return
    const distance = distanceKm >= 1 ? `${distanceKm.toFixed(1)} km` : `${Math.round(distanceKm * 1000)} m`
    this.hintTarget.textContent = `${distance} · ${direction}`
    this.hintTarget.classList.remove("hidden")
  }

  bearing(lat1, lng1, lat2, lng2) {
    const toRad = (deg) => (deg * Math.PI) / 180
    const y = Math.sin(toRad(lng2 - lng1)) * Math.cos(toRad(lat2))
    const x = Math.cos(toRad(lat1)) * Math.sin(toRad(lat2)) - Math.sin(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.cos(toRad(lng2 - lng1))
    const degrees = (Math.atan2(y, x) * 180 / Math.PI + 360) % 360
    const compass = (this.hasHintTarget && this.hintTarget.dataset.directions
      ? this.hintTarget.dataset.directions.split(",")
      : ["N", "NE", "E", "SE", "S", "SW", "W", "NW"])
    return compass[Math.round(degrees / 45) % 8]
  }

  distance(lat1, lng1, lat2, lng2) {
    const toRad = (deg) => (deg * Math.PI) / 180
    const dLat = toRad(lat2 - lat1)
    const dLng = toRad(lng2 - lng1)
    const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2
    return 2 * 6371 * Math.asin(Math.sqrt(a))
  }
}
