import { Controller } from "@hotwired/stimulus"

// Discloses the per-location moment forms on the plan page.
// Follows the toggleFilters/updateFiltersVisibility shape in
// listing_filters_controller.js.
export default class extends Controller {
  static targets = ["panel", "button", "label", "chevron"]

  static values = {
    expanded: { type: Boolean, default: false },
    openLabel: String,
    closedLabel: String
  }

  toggle(event) {
    event.preventDefault()
    this.expandedValue = !this.expandedValue
    this.updatePanelVisibility()
  }

  updatePanelVisibility() {
    if (this.expandedValue) {
      this.panelTarget.classList.remove("hidden")
      this.panelTarget.classList.add("block")
    } else {
      this.panelTarget.classList.add("hidden")
      this.panelTarget.classList.remove("block")
    }

    if (this.hasChevronTarget) {
      this.chevronTarget.classList.toggle("rotate-180", this.expandedValue)
    }

    this.buttonTarget.setAttribute("aria-expanded", String(this.expandedValue))

    if (this.hasOpenLabelValue && this.hasClosedLabelValue) {
      this.labelTarget.textContent = this.expandedValue ? this.openLabelValue : this.closedLabelValue
    }
  }
}
