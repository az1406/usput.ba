import { Controller } from "@hotwired/stimulus"
import { guestVisitsService } from "services/guest_visits_service"
import { positionService } from "services/position_service"

export default class extends Controller {
  static targets = ["hint", "control"]
  static values = { lat: Number, lng: Number, guest: Boolean, locationId: String }

  connect() {
    this.sending = false
    // A guest has no form to submit, so the button reports its own press.
    this.event = this.guestValue ? "click" : "submit"
    this.element.addEventListener(this.event, this.capture)
    this.unsubscribe = positionService.subscribe(() => {})
    if (this.guestValue && guestVisitsService.has(this.locationIdValue)) this.restoreVisited()
  }

  // Explore deals unvisited places only, so a visited one is dropped on a fresh
  // deal exactly as the server drops it for a signed-in traveller. The walk keeps
  // its visited steps, and so does a location page.
  restoreVisited() {
    const card = this.element.closest("[data-plan-deck-target='card']")
    const browsing = card?.closest("[data-plan-deck-browse-value='true']")
    if (!browsing) return this.markVisited()

    ;(card.closest(".snap-start") || card).remove()
  }

  disconnect() {
    this.element.removeEventListener(this.event, this.capture)
    this.unsubscribe?.()
  }

  capture = (event) => {
    if (this.sending) return
    event.preventDefault()

    // Out of this event first: requestSubmit() is ignored while the submit it
    // would re-trigger is still being dispatched.
    const here = positionService.fresh()
    if (here) return setTimeout(() => this.evaluate(here.latitude, here.longitude), 0)
    if (!navigator.geolocation) return this.showEnableLocation()

    // Nothing held yet — the first press on this page waits for one fix.
    navigator.geolocation.getCurrentPosition(
      (position) => this.evaluate(position.coords.latitude, position.coords.longitude),
      () => this.showEnableLocation(),
      { enableHighAccuracy: true, timeout: 10000 }
    )
  }

  evaluate(lat, lng) {
    const distanceKm = this.distance(lat, lng, this.latValue, this.lngValue)
    if (distanceKm <= 0.1) return this.guestValue ? this.recordGuestVisit() : this.submitWith(lat, lng)
    this.showHint(distanceKm, this.bearing(lat, lng, this.latValue, this.lngValue))
  }

  submitWith(lat, lng) {
    const form = this.element.querySelector("form")
    form.querySelector('input[name="user_lat"]').value = lat
    form.querySelector('input[name="user_lng"]').value = lng
    this.sending = true
    form.requestSubmit()
  }

  // Only the place is remembered, never where the traveller stood.
  recordGuestVisit() {
    this.sending = true
    guestVisitsService.add(this.locationIdValue)
    this.markVisited()
  }

  markVisited() {
    if (this.hasControlTarget) this.controlTarget.classList.add("hidden")
    if (this.hasHintTarget) this.hintTarget.classList.add("hidden")
    const card = this.element.closest("[data-plan-deck-target='card']")
    card?.setAttribute("data-plan-deck-visited", "true")
    const scope = this.element.closest("[data-walk-visited]") || card || this.element.parentElement
    scope?.querySelector("[data-visited-badge]")?.classList.remove("hidden")
  }

  showHint(distanceKm, direction) {
    if (!this.hasHintTarget) return
    const band = this.warmthBand(distanceKm)
    const distance = distanceKm >= 1 ? `${distanceKm.toFixed(1)} km` : `${Math.round(distanceKm * 1000)} m`
    this.hintTarget.textContent = `${band.emoji} ${band.label} · ${distance} · ${direction}`
    this.hintTarget.style.backgroundColor = band.tint
    this.hintTarget.classList.remove("hidden")
  }

  warmthBand(distanceKm) {
    // Cold → warm as the metres fall. HOT (<100 m) never reaches here —
    // evaluate() checks in at that range. Labels are localized via data-warmth;
    // tints are inline so Tailwind's purge can't drop dynamic colour classes.
    const labels = this.hintTarget.dataset.warmth
      ? this.hintTarget.dataset.warmth.split(",")
      : ["Freezing", "Cold", "Cool", "Warm"]
    const index = distanceKm > 5 ? 0 : distanceKm > 1 ? 1 : distanceKm > 0.5 ? 2 : 3
    const emoji = ["❄️", "🧊", "🌤️", "🔥"][index]
    const tint = ["rgba(37,99,235,.75)", "rgba(14,165,233,.75)", "rgba(234,179,8,.8)", "rgba(220,38,38,.85)"][index]
    return { label: labels[index], emoji, tint }
  }

  showEnableLocation() {
    if (!this.hasHintTarget) return
    this.hintTarget.textContent = this.hintTarget.dataset.enableLocation || "Enable location and try again."
    this.hintTarget.style.backgroundColor = ""
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
