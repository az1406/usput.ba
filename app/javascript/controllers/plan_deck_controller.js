import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card", "done", "distanceLabel"]
  static values = { browse: Boolean }

  connect() {
    this.index = 0
    // Browse mode (explore) keeps every card in the scroll; the walk deals one
    // at a time, opening on whichever is closest right now.
    if (!this.browseValue) {
      this.render()
      this.dealNearest(false)
    }
    // The server printed each card's distance from where you were at page load;
    // refresh it against where you actually are now (and again after check-in).
    this.refreshFromLocation()
  }


  advance() {
    const current = this.cardTargets[this.index]
    if (current && !this.isVisited(current)) return // can't skip an un-visited stop
    this.dealNearest(true)
  }

  // Nearest un-visited to the current position; re-run on open and each advance.
  dealNearest(advancing) {
    const remaining = this.cardTargets
      .map((card, i) => ({ card, i }))
      .filter(({ card }) => !this.isVisited(card))

    if (remaining.length === 0) {
      if (advancing) { this.index = this.cardTargets.length; this.render() }
      return
    }
    if (!navigator.geolocation) return this.show(remaining[0].i)

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const nearest = remaining
          .map((entry) => ({ ...entry, distance: this.distance(position.coords.latitude, position.coords.longitude, parseFloat(entry.card.dataset.planDeckLat), parseFloat(entry.card.dataset.planDeckLng)) }))
          .sort((a, b) => a.distance - b.distance)[0]
        this.show(nearest.i)
      },
      () => this.show(remaining[0].i),
      { enableHighAccuracy: true, timeout: 10000 }
    )
  }

  show(i) {
    this.index = i
    this.render()
  }

  render() {
    const done = this.index >= this.cardTargets.length
    this.cardTargets.forEach((card, i) => card.classList.toggle("hidden", done || i !== this.index))
    if (this.hasDoneTarget) this.doneTarget.classList.toggle("hidden", !done)
  }

  isVisited(card) {
    return card.dataset.planDeckVisited === "true" || card.querySelector("[data-walk-visited='true']") !== null
  }


  // One location read (cached, coarse — no watcher), then rewrite each card's
  // "X km away" from the current position.
  refreshFromLocation() {
    if (!this.hasDistanceLabelTarget || !navigator.geolocation) return
    navigator.geolocation.getCurrentPosition(
      (pos) => this.refreshDistances(pos.coords.latitude, pos.coords.longitude),
      () => {},
      { enableHighAccuracy: false, timeout: 5000, maximumAge: 60000 }
    )
  }

  refreshDistances(lat, lng) {
    this.distanceLabelTargets.forEach((label) => {
      const card = label.closest("[data-plan-deck-target='card']")
      const template = label.dataset.kmTemplate
      if (!card || !template) return
      const km = this.distance(lat, lng, parseFloat(card.dataset.planDeckLat), parseFloat(card.dataset.planDeckLng))
      label.textContent = template.replace("{km}", km.toFixed(1))
    })
  }


  distance(lat1, lng1, lat2, lng2) {
    if (Number.isNaN(lat2) || Number.isNaN(lng2)) return Infinity
    const toRad = (deg) => (deg * Math.PI) / 180
    const dLat = toRad(lat2 - lat1)
    const dLng = toRad(lng2 - lng1)
    const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2
    return 2 * 6371 * Math.asin(Math.sqrt(a))
  }
}
