import { Controller } from "@hotwired/stimulus"

// Tap the card photo to open its actions menu; each action shows one
// in-card panel (info / map / reviews). Moments go to the story viewer.
// A pulsing "tap for more" dot teaches the tap until the first open.
export default class extends Controller {
  static targets = ["menu", "panel", "hint", "locked"]

  connect() {
    if (this.hasHintTarget && !localStorage.getItem("usput-card-menu-hint-seen")) {
      this.hintTarget.classList.replace("hidden", "flex")
    }
    this.onSeen = () => this.hasHintTarget && this.hintTarget.classList.replace("flex", "hidden")
    window.addEventListener("card-menu:seen", this.onSeen)
  }

  disconnect() {
    window.removeEventListener("card-menu:seen", this.onSeen)
  }

  open(event) {
    if (event.target.closest("button, a, form, input, textarea, label")) return
    this.reveal()
  }

  openFromHint(event) {
    event.stopPropagation()
    this.reveal()
  }

  close(event) {
    event?.stopPropagation()
    this.menuTarget.classList.replace("flex", "hidden")
  }

  show(event) {
    event.stopPropagation()
    const name = event.currentTarget.dataset.panel
    this.menuTarget.classList.replace("flex", "hidden")
    this.panelTargets.forEach((panel) => panel.classList.toggle("hidden", panel.dataset.panel !== name))
    // Hidden-panel maps lay out at zero size; the map re-measures on resize.
    window.dispatchEvent(new Event("resize"))
  }

  // Moments are earned: no seeing or sharing until the location is visited.
  moments(event) {
    event.stopPropagation()
    if (this.visited()) {
      this.close()
      this.element.querySelector("[data-story-open]")?.click()
      return
    }
    if (!this.hasLockedTarget) return
    this.lockedTarget.classList.remove("hidden")
    setTimeout(() => this.lockedTarget.classList.add("hidden"), 2500)
  }

  visited() {
    return this.element.dataset.planDeckVisited === "true" ||
      this.element.querySelector("[data-walk-visited='true']") !== null
  }

  // Panel ✕ goes back to the menu, not straight out.
  back(event) {
    event?.stopPropagation()
    this.panelTargets.forEach((panel) => panel.classList.add("hidden"))
    this.menuTarget.classList.replace("hidden", "flex")
  }

  reveal() {
    localStorage.setItem("usput-card-menu-hint-seen", "1")
    window.dispatchEvent(new CustomEvent("card-menu:seen"))
    this.menuTarget.classList.replace("hidden", "flex")
  }
}
