import { Controller } from "@hotwired/stimulus"
import { positionService } from "services/position_service"

// The deck cannot deal without a position, so this reloads it with the first fix
// the shared watcher produces. Mounted only while the coordinates are missing.
export default class extends Controller {
  connect() {
    // Only a measured fix deals a deck. Handing off a remembered one had the
    // server order every card from wherever the device was last.
    const held = positionService.measured()
    if (held) return this.handOff(held)

    this.unsubscribe = positionService.subscribe((coords) => {
      this.stopListening()
      this.handOff(coords)
    })
  }

  disconnect() {
    this.stopListening()
  }

  stopListening() {
    this.unsubscribe?.()
    this.unsubscribe = undefined
  }

  handOff({ latitude, longitude }) {
    const url = new URL(window.location.href)
    if (url.searchParams.has("lat")) return

    url.searchParams.set("lat", latitude)
    url.searchParams.set("lng", longitude)
    window.location.replace(url.toString())
  }
}
