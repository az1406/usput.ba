import { Controller } from "@hotwired/stimulus"
import { positionService } from "services/position_service"

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
    return this.distance(lat, lng, parseFloat(card?.dataset.planDeckLat), parseFloat(card?.dataset.planDeckLng))
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
      .map((entry) => ({ ...entry, distance: this.distance(here.latitude, here.longitude, parseFloat(entry.card.dataset.planDeckLat), parseFloat(entry.card.dataset.planDeckLng)) }))
      .sort((a, b) => a.distance - b.distance)[0]
    this.show(nearest.i)
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
