import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

// Renders a simple OpenStreetMap view with pins, plus a full-viewport toggle.
// No API key required — tiles come from openstreetmap.org.
//
// Each point: { lat, lng, name, main?, url? }
export default class extends Controller {
  static targets = ["container", "fullscreenButton", "expandIcon", "collapseIcon"]
  static values = {
    lat: Number,
    lng: Number,
    points: Array,
  }

  connect() {
    this.expanded = false

    this.map = L.map(this.containerTarget, { scrollWheelZoom: false })
      .setView([this.latValue, this.lngValue], 14)

    L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 19,
      attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
    }).addTo(this.map)

    const bounds = []
    this.pointsValue.forEach((point) => {
      L.circleMarker([point.lat, point.lng], {
        radius: point.main ? 9 : 7,
        color: "#ffffff",
        weight: 2,
        fillColor: point.main ? "#059669" : "#64748b",
        fillOpacity: 1,
      })
        .addTo(this.map)
        .bindPopup(this.#popupFor(point))
      bounds.push([point.lat, point.lng])
    })

    if (bounds.length > 1) {
      this.map.fitBounds(bounds, { padding: [30, 30], maxZoom: 15 })
    }

    // Don't let clicks on the toggle button pan the map.
    if (this.hasFullscreenButtonTarget) {
      L.DomEvent.disableClickPropagation(this.fullscreenButtonTarget)
    }

    // Exit the expanded view with the Escape key.
    this.onKeydown = (event) => {
      if (event.key === "Escape" && this.expanded) this.toggleFullscreen()
    }
    document.addEventListener("keydown", this.onKeydown)
  }

  // Expand the map to fill the viewport (CSS overlay — works on every browser,
  // including iOS Safari, which the native Fullscreen API does not support for
  // non-video elements). Reverts to the inline card on toggle back.
  toggleFullscreen() {
    this.expanded = !this.expanded
    const style = this.containerTarget.style

    if (this.expanded) {
      Object.assign(style, {
        position: "fixed",
        inset: "0",
        width: "100%",
        height: "100%",
        zIndex: "9999",
        borderRadius: "0",
        margin: "0",
      })
      document.body.style.overflow = "hidden"
    } else {
      for (const prop of ["position", "inset", "width", "height", "zIndex", "borderRadius", "margin"]) {
        style[prop] = ""
      }
      document.body.style.overflow = ""
    }

    if (this.hasExpandIconTarget) this.expandIconTarget.classList.toggle("hidden", this.expanded)
    if (this.hasCollapseIconTarget) this.collapseIconTarget.classList.toggle("hidden", !this.expanded)

    // Let the layout settle, then tell Leaflet to recompute tile coverage.
    requestAnimationFrame(() => this.map?.invalidateSize())
  }

  disconnect() {
    document.removeEventListener("keydown", this.onKeydown)
    document.body.style.overflow = ""
    this.map?.remove()
    this.map = null
  }

  // Build the popup as a DOM node so the location name is never
  // interpreted as HTML (safe against markup in names).
  #popupFor(point) {
    const el = document.createElement(point.url ? "a" : "span")
    el.textContent = point.name
    el.className = "font-medium text-emerald-600"
    if (point.url) el.href = point.url
    return el
  }
}
