import { Controller } from "@hotwired/stimulus"
import { positionService } from "services/position_service"
import { distanceKm, profileFor, fetchRoute, summarise } from "services/route_service"

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
    // The server ordered the deck from where the traveller stood at page load.
    // From here the live position owns both the labels and the order.
    this.unsubscribe = positionService.subscribe(({ latitude, longitude }) => {
      this.refreshDistances(latitude, longitude)
      if (this.browseValue) this.resortAhead(latitude, longitude)
      this.routeCardInView(latitude, longitude)
    })
  }

  disconnect() {
    this.unsubscribe?.()
  }

  // Nearest-first, but only over the cards the traveller has not reached yet:
  // reordering what is on screen would move a card out from under their thumb.
  resortAhead(lat, lng) {
    const slots = this.slots()
    const current = this.currentSlot(slots)
    const ahead = slots.slice(current + 1)
    if (ahead.length < 2) return

    const sorted = [ ...ahead ].sort((a, b) => this.slotDistance(a, lat, lng) - this.slotDistance(b, lat, lng))
    if (sorted.every((slot, i) => slot === ahead[i])) return

    const anchor = ahead[ahead.length - 1].nextSibling
    sorted.forEach((slot) => slot.parentNode.insertBefore(slot, anchor))
  }

  slots() {
    return this.cardTargets
      .map((card) => card.closest(".snap-start"))
      .filter((slot, i, all) => slot && all.indexOf(slot) === i)
  }

  // The slot whose top is nearest the scroller's top is the one in view.
  currentSlot(slots) {
    const top = this.element.scrollTop
    let index = 0
    slots.forEach((slot, i) => {
      if (slot.offsetTop <= top + 1) index = i
    })
    return index
  }

  slotDistance(slot, lat, lng) {
    const card = slot.querySelector("[data-plan-deck-target='card']")
    return distanceKm(lat, lng, parseFloat(card?.dataset.planDeckLat), parseFloat(card?.dataset.planDeckLng))
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
    const here = positionService.current()
    if (!here) return this.show(remaining[0].i)

    const nearest = remaining
      .map((entry) => ({ ...entry, distance: distanceKm(here.latitude, here.longitude, parseFloat(entry.card.dataset.planDeckLat), parseFloat(entry.card.dataset.planDeckLng)) }))
      .sort((a, b) => a.distance - b.distance)[0]
    this.show(nearest.i)
  }

  show(i) {
    this.index = i
    this.render()
    const here = positionService.current()
    if (here) this.routeCardInView(here.latitude, here.longitude)
  }

  render() {
    const done = this.index >= this.cardTargets.length
    this.cardTargets.forEach((card, i) => card.classList.toggle("hidden", done || i !== this.index))
    if (this.hasDoneTarget) this.doneTarget.classList.toggle("hidden", !done)
  }

  isVisited(card) {
    return card.dataset.planDeckVisited === "true" || card.querySelector("[data-walk-visited='true']") !== null
  }


  // The straight line is what a card can afford to show for every place at once.
  // The real road distance costs an upstream routing call, so only the card the
  // traveller is actually looking at gets one, and only once.
  async routeCardInView(lat, lng) {
    const card = this.cardInView()
    const label = card?.querySelector("[data-plan-deck-target='distanceLabel']")
    if (!card || !label || label.dataset.routed) return

    const to = { lat: parseFloat(card.dataset.planDeckLat), lng: parseFloat(card.dataset.planDeckLng) }
    if (Number.isNaN(to.lat) || Number.isNaN(to.lng)) return

    label.dataset.routed = "pending"
    const profile = profileFor(distanceKm(lat, lng, to.lat, to.lng))
    const route = await fetchRoute({ fromLat: lat, fromLng: lng, toLat: to.lat, toLng: to.lng, profile })

    // A refused or throttled lookup leaves the straight line standing, and
    // clears the flag so moving somewhere else can try again.
    if (!route) return delete label.dataset.routed

    label.dataset.routed = "true"
    label.textContent = summarise(route, { byFoot: label.dataset.byFoot, byCar: label.dataset.byCar })
  }

  cardInView() {
    if (!this.browseValue) return this.cardTargets[this.index]
    const slots = this.slots()
    return slots[this.currentSlot(slots)]?.querySelector("[data-plan-deck-target='card']")
  }

  refreshDistances(lat, lng) {
    this.distanceLabelTargets.forEach((label) => {
      const card = label.closest("[data-plan-deck-target='card']")
      const template = label.dataset.kmTemplate
      // A card showing a real road distance keeps it; overwriting would flip it
      // back to the straight line on the next position update.
      if (!card || !template || label.dataset.routed) return
      const km = distanceKm(lat, lng, parseFloat(card.dataset.planDeckLat), parseFloat(card.dataset.planDeckLng))
      label.textContent = template.replace("{km}", km.toFixed(1))
    })
  }
}
