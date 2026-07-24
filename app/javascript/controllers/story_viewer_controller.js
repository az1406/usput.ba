import { Controller } from "@hotwired/stimulus"

// Story carousel: full-width cards side by side in a
// snap-scroll track — swipe on touch, arrow buttons on desktop. First card
// adds your memory, then your private moments, then the published ones.
export default class extends Controller {
  static targets = ["overlay", "track", "slide"]

  open(event) {
    event?.stopPropagation()
    this.openAt(0)
  }

  openAt(index) {
    // A native dialog lives in the browser's top layer — above every
    // stacking context, banners and navbars included. Escape is native too.
    if (!this.overlayTarget.open) this.overlayTarget.showModal()
    document.body.classList.add("overflow-hidden", "story-open")
    requestAnimationFrame(() => this.scrollToIndex(index))
    this.onKey ||= (keyEvent) => {
      if (keyEvent.key === "ArrowRight") this.next()
      else if (keyEvent.key === "ArrowLeft") this.prev()
    }
    document.addEventListener("keydown", this.onKey)
  }

  // Fired by the dialog itself (Escape, programmatic close) — just clean up.
  onNativeClose() {
    document.body.classList.remove("overflow-hidden", "story-open")
    if (this.onKey) document.removeEventListener("keydown", this.onKey)
  }

  // Content first, creation is a button: + opens the camera/gallery through
  // the hidden upload form; the morphed-in slide then scrolls into view.
  addMoment(event) {
    event.stopPropagation()
    const hint = this.element.querySelector("[data-hint-key-value='usput-add-moment-hint-seen']")
    if (hint) {
      localStorage.setItem("usput-add-moment-hint-seen", "1")
      hint.classList.replace("flex", "hidden")
    }
    const input = this.element.querySelector("[data-story-upload] input[type=file]")
    if (!input) return
    input.value = "" // let the same photo be picked again for another moment
    input.click()
  }

  noteUpload() {
    this.pendingNewSlide = true
  }

  noteDelete() {
    this.pendingNewSlide = false
  }

  slideTargetConnected() {
    if (!this.pendingNewSlide) return
    this.pendingNewSlide = false
    // newest sorts to index 0; jump there — the morph may insert the node elsewhere
    requestAnimationFrame(() => this.scrollToIndex(0))
  }

  next() {
    this.scrollToIndex(this.currentIndex() + 1)
  }

  prev() {
    this.scrollToIndex(this.currentIndex() - 1)
  }

  currentIndex() {
    return Math.round(this.trackTarget.scrollLeft / this.trackTarget.clientWidth)
  }

  scrollToIndex(index) {
    const clamped = Math.max(0, Math.min(index, this.slideTargets.length - 1))
    this.trackTarget.scrollTo({ left: clamped * this.trackTarget.clientWidth, behavior: "smooth" })
  }

  close() {
    if (this.overlayTarget.open) this.overlayTarget.close()
    this.onNativeClose()
    this.dispatch("closed")
  }

  closeOnBackground(event) {
    if (event.target === event.currentTarget) this.close()
  }

  disconnect() {
    this.onNativeClose()
  }
}
