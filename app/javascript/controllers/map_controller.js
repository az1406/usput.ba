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
    userLocation: Boolean,
  }

  connect() {
    this.expanded = false

    this.map = L.map(this.containerTarget, { scrollWheelZoom: false })
      .setView([this.latValue, this.lngValue], 15)

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

    if (this.hasFullscreenButtonTarget) {
      L.DomEvent.disableClickPropagation(this.fullscreenButtonTarget)
    }

    this.onKeydown = (event) => {
      if (event.key === "Escape" && this.expanded) this.toggleFullscreen()
    }
    document.addEventListener("keydown", this.onKeydown)

    // Hidden-panel maps lay out at zero size; re-measure + locate on reveal.
    this.onResize = () => {
      this.map?.invalidateSize()
      if (this.userLocationValue && !this.located && this.containerTarget.offsetParent !== null) this.#locateUser()
    }
    window.addEventListener("resize", this.onResize)
  }

  #locateUser() {
    if (!navigator.geolocation) return
    this.located = true
    navigator.geolocation.getCurrentPosition((position) => {
      const here = [position.coords.latitude, position.coords.longitude]
      const target = this.pointsValue[0]
      this.userMarker = L.circleMarker(here, { radius: 8, color: "#ffffff", weight: 2, fillColor: "#2563eb", fillOpacity: 1 }).addTo(this.map)
      if (!target) return
      this.routeOrigin = here
      this.#drawPath(here, target)
      // A desktop IP fix can be far off — only zoom to include the user when near.
      if (this.#distanceKm(here[0], here[1], target.lat, target.lng) < 3) {
        this.map.fitBounds([here, [target.lat, target.lng]], { padding: [40, 40], maxZoom: 16 })
      }
      this.#followUser()
    })
  }

  // The dot walks with you while the map is on screen; the route re-fetches
  // once you have drifted well off its start. Watching stops the moment the
  // map is hidden so it can never interfere with the check-in's geolocation.
  #followUser() {
    this.watchId = navigator.geolocation.watchPosition((position) => {
      if (this.containerTarget.offsetParent === null) return this.#stopFollowing()
      const here = [position.coords.latitude, position.coords.longitude]
      this.userMarker?.setLatLng(here)
      const target = this.pointsValue[0]
      if (!target || !this.routeOrigin) return
      if (this.#distanceKm(here[0], here[1], this.routeOrigin[0], this.routeOrigin[1]) > 0.15) {
        this.routeOrigin = here
        this.#clearPath()
        this.#drawPath(here, target)
      }
    }, () => {}, { enableHighAccuracy: true })
  }

  #stopFollowing() {
    if (this.watchId !== undefined) navigator.geolocation.clearWatch(this.watchId)
    this.watchId = undefined
    this.located = false
  }

  #clearPath() {
    this.routeLayer?.remove()
    this.routeChip?.remove()
    this.routeLayer = this.routeChip = null
  }

  // The real walking route when the proxy can deliver one; a straight dashed
  // line otherwise — routing degrades, it never breaks the map.
  async #drawPath(here, target) {
    try {
      const query = new URLSearchParams({ from_lat: here[0], from_lng: here[1], to_lat: target.lat, to_lng: target.lng })
      const response = await fetch(`/route?${query}`, { headers: { Accept: "application/json" } })
      if (!response.ok) throw new Error(`route ${response.status}`)
      const route = await response.json()
      const firstDraw = !this.routeLayer
      this.routeLayer = L.polyline(route.points, { color: "#2563eb", weight: 4, opacity: 0.85 }).addTo(this.map)
      this.#addRouteChip(route)
      if (firstDraw) this.map.fitBounds(route.points, { padding: [30, 30], maxZoom: 16 })
    } catch {
      this.routeLayer = L.polyline([here, [target.lat, target.lng]], { color: "#2563eb", weight: 3, opacity: 0.7, dashArray: "6 6" }).addTo(this.map)
    }
  }

  #addRouteChip(route) {
    this.routeChip?.remove()
    const chip = L.control({ position: "bottomleft" })
    chip.onAdd = () => {
      const el = L.DomUtil.create("div")
      el.className = "rounded-full bg-white/95 px-3 py-1 text-xs font-semibold text-gray-900 shadow dark:bg-gray-900/90 dark:text-gray-100"
      const km = (route.distance_m / 1000).toFixed(1)
      const min = Math.max(1, Math.round(route.duration_s / 60))
      el.textContent = `${km} km · ${min} min`
      return el
    }
    chip.addTo(this.map)
    this.routeChip = chip
  }

  #distanceKm(lat1, lng1, lat2, lng2) {
    const toRad = (deg) => (deg * Math.PI) / 180
    const dLat = toRad(lat2 - lat1)
    const dLng = toRad(lng2 - lng1)
    const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2
    return 2 * 6371 * Math.asin(Math.sqrt(a))
  }

  toggleFullscreen() {
    this.expanded = !this.expanded
    const style = this.containerTarget.style

    if (this.expanded) {
      Object.assign(style, { position: "fixed", inset: "0", width: "100%", height: "100%", zIndex: "9999", borderRadius: "0", margin: "0" })
      document.body.style.overflow = "hidden"
    } else {
      for (const prop of ["position", "inset", "width", "height", "zIndex", "borderRadius", "margin"]) style[prop] = ""
      document.body.style.overflow = ""
    }

    if (this.hasExpandIconTarget) this.expandIconTarget.classList.toggle("hidden", this.expanded)
    if (this.hasCollapseIconTarget) this.collapseIconTarget.classList.toggle("hidden", !this.expanded)

    requestAnimationFrame(() => this.map?.invalidateSize())
  }

  disconnect() {
    this.#stopFollowing()
    document.removeEventListener("keydown", this.onKeydown)
    window.removeEventListener("resize", this.onResize)
    document.body.style.overflow = ""
    this.map?.remove()
    this.map = null
  }

  // Build the popup as a DOM node so the location name is never interpreted as
  // HTML (safe against markup in names).
  #popupFor(point) {
    const el = document.createElement(point.url ? "a" : "span")
    el.textContent = point.name
    el.className = "font-medium text-emerald-600"
    if (point.url) el.href = point.url
    return el
  }
}
