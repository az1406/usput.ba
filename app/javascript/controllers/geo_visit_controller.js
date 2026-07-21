import { Controller } from "@hotwired/stimulus"

// Sends the visitor's coordinates with the "I was here" form so the server can
// verify they are actually at the place before marking it visited.
export default class extends Controller {
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

    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => this.submitWith(position.coords.latitude, position.coords.longitude),
        () => this.submitWith(0, 0),
        { enableHighAccuracy: true, timeout: 10000 }
      )
    } else {
      this.submitWith(0, 0)
    }
  }

  submitWith(lat, lng) {
    this.element.querySelector('input[name="user_lat"]').value = lat
    this.element.querySelector('input[name="user_lng"]').value = lng
    this.sending = true
    this.element.requestSubmit()
  }
}
