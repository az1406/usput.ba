import { Controller } from "@hotwired/stimulus"
import { positionService } from "services/position_service"
import "leaflet"
import "leaflet.markercluster"

const L = window.L

// Below this the pins stand alone: a town fits on screen, which is where the
// operator wants to stop seeing bubbles.
const CLUSTER_UNTIL_ZOOM = 13
// Past this nobody is walking, so asking the routing service is a request that
// was always going to be refused. Show the distance instead.
const MAX_WALKING_KM = 30
// Every map on the page wants the same catalogue, and the explore reel mounts
// one per card. Fetch it once per page, and keep it for the session so moving
// between places does not re-download the country. The version is the newest
// content edit, so a stale copy is simply a key nobody asks for.
let cataloguePromise = null

function catalogue(version) {
  if (cataloguePromise) return cataloguePromise

  const key = `usput_map_points/${version}`
  const held = sessionStorage.getItem(key)
  if (held) {
    try {
      cataloguePromise = Promise.resolve(JSON.parse(held))
      return cataloguePromise
    } catch {
      sessionStorage.removeItem(key)
    }
  }

  cataloguePromise = fetch("/locations/map_points", { headers: { Accept: "application/json" } })
    .then((response) => (response.ok ? response.json() : Promise.reject(new Error(response.status))))
    .then((points) => {
      try {
        Object.keys(sessionStorage)
          .filter((held) => held.startsWith("usput_map_points/") && held !== key)
          .forEach((stale) => sessionStorage.removeItem(stale))
        sessionStorage.setItem(key, JSON.stringify(points))
      } catch {
        // A full quota is not a reason to lose the map.
      }
      return points
    })
    .catch(() => {
      // null is "we could not load", [] is "there is nothing" — the map says
      // different things about each, and a retry is only sane for the first.
      cataloguePromise = null
      return null
    })

  return cataloguePromise
}

// Renders a simple OpenStreetMap view with pins, plus a full-viewport toggle.
// No API key required — tiles come from openstreetmap.org.
//
// Each point: { lat, lng, name, main?, url? }
export default class extends Controller {
  static targets = ["container", "fullscreenButton", "expandIcon", "collapseIcon", "panel", "panelFrame"]
  static values = {
    lat: Number,
    lng: Number,
    points: Array,
    userLocation: Boolean,
    catalogue: Boolean,
    catalogueVersion: Number,
    awayLabel: String,
    loadFailedLabel: String,
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
      bounds.push([point.lat, point.lng])
      // With the catalogue on, this place is drawn by it — clustered like the
      // rest, so zooming out groups it instead of leaving one pin behind.
      if (this.catalogueValue) return

      L.circleMarker([point.lat, point.lng], {
        radius: point.main ? 9 : 7,
        color: "#ffffff",
        weight: 2,
        fillColor: point.main ? "#059669" : "#64748b",
        fillOpacity: 1,
      })
        .addTo(this.map)
        .bindPopup(this.#popupFor(point))
    })

    if (bounds.length > 1) {
      this.map.fitBounds(bounds, { padding: [30, 30], maxZoom: 15 })
    }

    if (this.catalogueValue) this.#loadCatalogue()
    if (this.userLocationValue) this.#locateUser()

    if (this.hasFullscreenButtonTarget) {
      L.DomEvent.disableClickPropagation(this.fullscreenButtonTarget)
    }

    // The panel sits inside the map element so it survives the fullscreen
    // toggle, which means Leaflet would otherwise treat every click and scroll
    // inside it as a map gesture — including the links Turbo needs to handle.
    if (this.hasPanelTarget) {
      L.DomEvent.disableClickPropagation(this.panelTarget)
      L.DomEvent.disableScrollPropagation(this.panelTarget)
    }

    this.onKeydown = (event) => {
      if (event.key === "Escape" && this.expanded) this.toggleFullscreen()
    }
    document.addEventListener("keydown", this.onKeydown)

    // Hidden-panel maps lay out at zero size; re-measure + locate on reveal.
    this.onResize = () => {
      this.map?.invalidateSize()
      if (this.userLocationValue && !this.located && this.#onScreen()) this.#locateUser()
    }
    window.addEventListener("resize", this.onResize)
  }

  // The whole catalogue, clustered. Chunked because building the layer in one
  // go blocks the main thread once the country is in it.
  async #loadCatalogue() {
    const points = await catalogue(this.catalogueVersionValue)
    if (!this.map) return
    if (points === null) return this.#showChip(this.loadFailedLabelValue)
    if (points.length === 0) return

    this.clusters = L.markerClusterGroup({
      chunkedLoading: true,
      disableClusteringAtZoom: CLUSTER_UNTIL_ZOOM,
      spiderfyOnMaxZoom: false,
      showCoverageOnHover: false,
    })

    this.selectedId = this.pointsValue.find((point) => point.main)?.id
    this.markers = new Map()

    points.forEach((point) => {
      const selected = point.id === this.selectedId
      const marker = L.marker([point.lat, point.lng], {
        icon: this.#iconFor({ selected }),
        zIndexOffset: selected ? 1000 : 0,
      })
      marker.on("click", () => {
        this.#select(point.id)
        this.#routeTo(point)
        // Only the maps that carry a panel open one; the walk and the reel
        // keep their own surface and just re-route.
        if (!this.hasPanelTarget) return
        if (!this.expanded) this.toggleFullscreen()
        this.#openPanel(point.id)
      })
      this.markers.set(point.id, marker)
      this.clusters.addLayer(marker)
    })

    this.map.addLayer(this.clusters)
  }

  #iconFor({ selected = false } = {}) {
    const width = selected ? 34 : 24
    const height = selected ? 46 : 33

    return L.divIcon({
      className: "",
      html: `<svg width="${width}" height="${height}" viewBox="0 0 24 33">
        <path d="M12 0C5.37 0 0 5.37 0 12c0 8.25 12 21 12 21s12-12.75 12-21C24 5.37 18.63 0 12 0z"
              fill="${selected ? "#059669" : "#e11d48"}" stroke="#ffffff" stroke-width="2.5"/>
        <circle cx="12" cy="12" r="4.2" fill="#ffffff"/>
      </svg>`,
      iconSize: [width, height],
      iconAnchor: [width / 2, height],
      popupAnchor: [0, -height],
    })
  }

  // Selection follows the traveller: the place they arrived on starts selected,
  // and clicking another hands the larger icon over to it.
  #select(id) {
    if (this.selectedId === id) return

    const previous = this.markers?.get(this.selectedId)
    if (previous) previous.setIcon(this.#iconFor())

    const next = this.markers?.get(id)
    if (next) {
      next.setIcon(this.#iconFor({ selected: true }))
      next.setZIndexOffset(1000)
    }
    this.selectedId = id
  }

  // Walking directions to whatever was tapped. Prefer where the traveller
  // actually is; without a fix, route from the place the page is about, so the
  // line still answers "how do I get there from here".
  #routeTo(point) {
    this.routeTarget = point
    this.#clearPath()

    const measured = positionService.measured()
    if (measured) {
      this.routeOrigin = [measured.latitude, measured.longitude]
      this.#drawPath(this.routeOrigin, point)
      this.#followUser()
      return
    }

    const origin = this.pointsValue.find((candidate) => candidate.main)
    if (!origin || origin.id === point.id) return

    this.routeOrigin = [origin.lat, origin.lng]
    this.#drawPath(this.routeOrigin, point)
  }

  #openPanel(id) {
    if (!this.hasPanelTarget) return

    this.map.closePopup()
    this.panelFrameTarget.src = `/locations/${id}/map_panel`
    this.panelTarget.classList.remove("hidden")
    requestAnimationFrame(() => this.map?.invalidateSize())
  }

  closePanel() {
    if (!this.hasPanelTarget) return

    this.panelTarget.classList.add("hidden")
    this.panelFrameTarget.removeAttribute("src")
    this.panelFrameTarget.innerHTML = ""
    requestAnimationFrame(() => this.map?.invalidateSize())
  }


  #locateUser() {
    if (!navigator.geolocation) return
    this.located = true
    this.#onFirstFix((coords) => {
      const here = [coords.latitude, coords.longitude]
      const target = this.routeTarget || this.pointsValue[0]
      this.userMarker = L.circleMarker(here, { radius: 8, color: "#ffffff", weight: 2, fillColor: "#2563eb", fillOpacity: 1 }).addTo(this.map)
      this.#followUser()
      if (!target) return
      this.routeTarget = target
      this.routeOrigin = here
      this.#drawPath(here, target)
      // A desktop IP fix can be far off — only zoom to include the user when near.
      if (this.#distanceKm(here[0], here[1], target.lat, target.lng) < 3) {
        this.map.fitBounds([here, [target.lat, target.lng]], { padding: [40, 40], maxZoom: 16 })
      }
    })
  }

  // One fix from the shared watcher, whether or not it has one yet.
  #onFirstFix(handler) {
    const held = positionService.measured()
    if (held) return handler(held)

    const stop = positionService.subscribe((coords) => {
      stop()
      handler(coords)
    })
  }

  // The dot walks with you while the map is on screen; the route re-fetches once
  // you have drifted well off its start. The subscription drops when the map is
  // hidden, which stops the watcher if nothing else is listening.
  #followUser() {
    if (this.unfollow) return

    this.unfollow = positionService.subscribe((coords) => {
      if (!this.#onScreen()) return this.#stopFollowing()
      const here = [coords.latitude, coords.longitude]
      this.userMarker?.setLatLng(here)
      const target = this.routeTarget
      if (!target || !this.routeOrigin) return
      if (this.#distanceKm(here[0], here[1], this.routeOrigin[0], this.routeOrigin[1]) > 0.15) {
        this.routeOrigin = here
        this.#clearPath()
        this.#drawPath(here, target)
      }
    })
  }

  // offsetParent is null for a fixed element, and fullscreen makes the map
  // fixed — so testing it stopped the position following the moment the map
  // went fullscreen. Client rects are honest for both.
  #onScreen() {
    return this.containerTarget.getClientRects().length > 0
  }

  #stopFollowing() {
    this.unfollow?.()
    this.unfollow = undefined
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
    const km = this.#distanceKm(here[0], here[1], target.lat, target.lng)
    if (km > MAX_WALKING_KM) return this.#showTooFar(here, target, km)

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
      // The dashed fallback needs framing as much as a real route does — more,
      // since routing fails exactly when the two points are far apart.
      this.routeLayer = L.polyline([here, [target.lat, target.lng]], { color: "#2563eb", weight: 3, opacity: 0.7, dashArray: "6 6" }).addTo(this.map)
      this.#frame([here, [target.lat, target.lng]])
    }
  }

  // Too far to walk: no line implying a path, just where it is and how far.
  #showTooFar(here, target, km) {
    this.#addDistanceChip(km)
    this.#frame([here, [target.lat, target.lng]])
  }

  // Phones have less room than the desktop route framing assumes, and two
  // distant points would otherwise zoom out past anything legible.
  #frame(points) {
    const tight = this.containerTarget.clientWidth < 480
    this.map.fitBounds(points, { padding: tight ? [16, 16] : [30, 30], maxZoom: 15 })
  }

  #addRouteChip(route) {
    const km = (route.distance_m / 1000).toFixed(1)
    const min = Math.max(1, Math.round(route.duration_s / 60))
    this.#showChip(`${km} km · ${min} min`)
  }

  #addDistanceChip(km) {
    this.#showChip(this.awayLabelValue.replace("%{km}", km.toFixed(0)))
  }

  #showChip(text) {
    this.routeChip?.remove()
    const chip = L.control({ position: "bottomleft" })
    chip.onAdd = () => {
      const el = L.DomUtil.create("div")
      el.className = "rounded-full bg-white/95 px-3 py-1 text-xs font-semibold text-gray-900 shadow dark:bg-gray-900/90 dark:text-gray-100"
      el.textContent = text
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
    if (!this.expanded) this.closePanel()
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
    this.clusters?.clearLayers()
    this.clusters = null
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
