import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card", "done", "hint", "storyHint", "reelHint"]
  static values = { browse: Boolean }

  connect() {
    this.index = 0
    if (this.browseValue) {
      // Browse mode (explore): every card stays visible — scroll through them,
      // closest first. Swipe works per card.
      this.maybeShowReelHint()
    } else {
      this.render()
      // Open on the place closest to where you are right now, not plan order.
      this.dealNearest(false)
    }
    this.maybeShowHint()
    this.bindSwipe()
    this.maybeShowStoryHints()
    // A confirmed check-in arrives as a Turbo Stream; teach the left swipe then.
    this.onStream = () => setTimeout(() => this.maybeShowStoryHints(), 100)
    document.addEventListener("turbo:before-stream-render", this.onStream)
  }

  disconnect() {
    document.removeEventListener("turbo:before-stream-render", this.onStream)
  }

  maybeShowStoryHints() {
    if (localStorage.getItem("usput-story-hint-seen")) return
    this.cardTargets.forEach((card) => {
      if (!this.isVisited(card)) return
      card.querySelectorAll("[data-plan-deck-target='storyHint']").forEach((hint) => hint.classList.replace("hidden", "flex"))
    })
  }

  maybeShowHint() {
    if (localStorage.getItem("usput-swipe-hint-seen")) return
    this.hintTargets.forEach((hint) => hint.classList.replace("hidden", "flex"))
  }

  dismissHint(event) {
    event?.stopPropagation()
    localStorage.setItem("usput-swipe-hint-seen", "1")
    this.hintTargets.forEach((hint) => hint.classList.replace("flex", "hidden"))
  }

  maybeShowReelHint() {
    if (localStorage.getItem("usput-reel-hint-seen")) return
    if (this.cardTargets.length <= 1 || !this.hasReelHintTarget) return
    this.reelHintTarget.classList.replace("hidden", "flex")
    this.element.addEventListener("scroll", this.dismissReelHint, { once: true, passive: true })
  }

  dismissReelHint = () => {
    localStorage.setItem("usput-reel-hint-seen", "1")
    if (this.hasReelHintTarget) this.reelHintTarget.classList.replace("flex", "hidden")
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

  // Right drag past the commit point checks in (left opens stories), on any
  // pointer — finger or mouse — so desktop swipes too.
  bindSwipe() {
    const MAX = 140
    const COMMIT = 80
    let startX = 0
    let startY = 0
    let dragging = false

    // Drags inside the story overlay or a card panel are theirs, not the deck's;
    // and the browser's native image-drag must never hijack the gesture.
    this.element.addEventListener("dragstart", (event) => event.preventDefault())

    // A drag's pointerup is followed by a synthetic click — swallow it so a
    // swipe never doubles as a tap that opens the card menu.
    this.element.addEventListener("click", (event) => {
      if (!event.isTrusted || !this.suppressClick) return
      this.suppressClick = false
      event.preventDefault()
      event.stopPropagation()
    }, { capture: true })

    this.element.addEventListener("pointerdown", (event) => {
      if (!event.isPrimary) return
      if (event.target.closest("[data-story-viewer-target='overlay'], [data-card-menu-target='menu'], [data-card-menu-target='panel']")) return
      startX = event.clientX
      startY = event.clientY
      this.activeCard = this.browseValue
        ? event.target.closest("[data-plan-deck-target='card']")
        : this.cardTargets[this.index]
      dragging = true
    })

    this.element.addEventListener("pointermove", (event) => {
      if (!dragging || !event.isPrimary) return
      const card = this.activeCard
      if (!card) return
      const dx = event.clientX - startX
      const dy = event.clientY - startY
      if (Math.abs(dx) > Math.abs(dy)) {
        if (event.pointerType === "mouse") event.preventDefault()
        const capped = Math.max(Math.min(dx, MAX), -MAX)
        card.style.transform = `translateX(${capped}px) rotate(${capped * 0.02}deg)`
      }
    })

    this.element.addEventListener("pointerup", (event) => {
      if (!dragging || !event.isPrimary) return
      dragging = false
      const card = this.activeCard
      if (!card) return
      const dx = event.clientX - startX
      const dy = event.clientY - startY
      this.suppressClick = Math.hypot(dx, dy) > 10
      const horizontal = Math.abs(dx) > Math.abs(dy)
      const committed = horizontal && dx > COMMIT
      const committedLeft = horizontal && dx < -COMMIT
      if (committed || committedLeft) this.dismissHint()

      if (committed && this.isVisited(card)) {
        // Browse mode: a repeat right-swipe is just "already visited" — the
        // card stays in the scroll. The walk's deal-one deck still advances.
        if (this.browseValue) return this.snapBack(card)
        this.flyAway(card)
        return
      }
      this.snapBack(card)
      if (committed) this.checkIn(card)
      if (committedLeft) this.openStories(card)
    })

    this.element.addEventListener("pointercancel", () => {
      if (dragging && this.activeCard) this.snapBack(this.activeCard)
      dragging = false
    })
  }

  snapBack(card) {
    card.style.transition = "transform 0.2s ease"
    card.style.transform = ""
    setTimeout(() => { card.style.transition = "" }, 200)
  }

  openStories(card) {
    if (!this.isVisited(card)) {
      const locked = card.querySelector("[data-card-menu-target='locked']")
      if (locked) {
        locked.classList.remove("hidden")
        setTimeout(() => locked.classList.add("hidden"), 2500)
      }
      return
    }
    localStorage.setItem("usput-story-hint-seen", "1")
    this.storyHintTargets.forEach((hint) => hint.classList.replace("flex", "hidden"))
    card.querySelector("[data-story-open]")?.click()
  }

  checkIn(card) {
    const form = card.querySelector("form[action*='visits']")
    if (form) form.requestSubmit() // geo-visit intercepts: checks distance, then submits or hints
  }

  flyAway(card) {
    card.style.transition = "transform 0.25s ease, opacity 0.25s ease"
    card.style.transform = "translateX(120%) rotate(6deg)"
    card.style.opacity = "0"
    const reset = () => {
      card.removeEventListener("transitionend", reset)
      card.style.transition = ""
      card.style.transform = ""
      card.style.opacity = ""
      if (this.browseValue) return card.classList.add("hidden")
      this.advance()
    }
    card.addEventListener("transitionend", reset)
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
