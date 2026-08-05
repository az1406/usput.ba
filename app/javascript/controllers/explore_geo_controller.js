import { Controller } from "@hotwired/stimulus"
import { positionService } from "services/position_service"

// The deck cannot deal without a position, so this reloads it with the first fix
// the shared watcher produces. Mounted only while the coordinates are missing.
export default class extends Controller {
  static values = { failedBody: String, retryLabel: String }

  connect() {
    // Only a measured fix deals a deck. Handing off a remembered one had the
    // server order every card from wherever the device was last.
    const held = positionService.measured()
    if (held) return this.handOff(held)

    this.unsubscribe = positionService.subscribe(
      (coords) => {
        this.stopListening()
        this.handOff(coords)
      },
      () => this.showFailed()
    )
  }

  disconnect() {
    this.stopListening()
  }

  stopListening() {
    this.unsubscribe?.()
    this.unsubscribe = undefined
  }

  showFailed() {
    const card = this.element.querySelector("[data-plan-deck-target='card']")
    if (!card || card.dataset.geoFailed) return
    card.dataset.geoFailed = "true"

    const message = card.querySelector("p")
    if (message) message.textContent = this.failedBodyValue

    const retry = document.createElement("button")
    retry.type = "button"
    retry.textContent = this.retryLabelValue
    retry.className = "mt-4 rounded-full bg-gray-900 px-5 py-2 text-sm font-semibold text-white dark:bg-white dark:text-gray-900"
    retry.addEventListener("click", () => window.location.reload())
    message?.after(retry)
  }

  // The deck lives in a Turbo frame, so the fix can be handed over by asking
  // that frame to re-render rather than by replacing the document.
  handOff({ latitude, longitude }) {
    const url = new URL(window.location.href)
    if (url.searchParams.has("lat")) return

    url.searchParams.set("lat", latitude)
    url.searchParams.set("lng", longitude)

    const frame = document.getElementById("explore_deck")
    if (!frame) return window.location.replace(url.toString())

    window.history.replaceState({}, "", url.toString())
    frame.src = url.toString()
  }
}
