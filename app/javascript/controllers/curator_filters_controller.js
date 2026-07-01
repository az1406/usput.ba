import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="curator-filters"
export default class extends Controller {
  static targets = ["content", "icon"]
  static values = {
    expanded: { type: Boolean, default: false }
  }

  toggle() {
    this.expandedValue = !this.expandedValue
  }

  expandedValueChanged() {
    if (this.hasContentTarget) {
      if (this.expandedValue) {
        // Force display by using inline style to override Tailwind responsive classes
        this.contentTarget.style.display = "block"
      } else {
        this.contentTarget.style.display = "none"
      }
    }

    if (this.hasIconTarget) {
      if (this.expandedValue) {
        this.iconTarget.classList.add("rotate-180")
      } else {
        this.iconTarget.classList.remove("rotate-180")
      }
    }
  }
}
