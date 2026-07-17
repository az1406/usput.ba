import { Controller } from "@hotwired/stimulus"

// Prints the traveller's moments as a passport booklet: a cover, a data page,
// then one stamped page per moment.
//
// Mirrors the boarding-pass print in travel_profile_controller.js — a popup
// written with document.write and handed to the browser's print dialog — with
// one necessary difference. A boarding pass is text and CSS, so it can call
// print() immediately; a passport is mostly photos, and print() fires before
// the browser has fetched any of them, which prints empty squares. So the
// images are awaited first.
//
// Pages are 88x125mm — the real passport booklet size — rather than A4, so the
// popup shows something compact instead of a wall of paper.
export default class extends Controller {
  static values = {
    holder: String, // username of the passport holder
    number: String, // stable per traveller — derived from the user's UUID
    issued: String, // formatted date, printed on the data page
    moments: Array, // [{ location, city, type, note, photo, trip }]
    translations: Object // I18n translations passed from Rails
  }

  static targets = ["printButton"]

  static PROFILE_STORAGE_KEY = "usput_travel_profile"

  connect() {
    if (this.hasPrintButtonTarget) {
      this.printButtonTarget.disabled = this.momentsValue.length === 0
    }
  }

  async print(event) {
    event.preventDefault()
    if (this.momentsValue.length === 0) return

    const printWindow = window.open("", "_blank")
    if (!printWindow) return

    printWindow.document.write(this.#documentHtml())
    printWindow.document.close()

    await this.#imagesSettled(printWindow)
    printWindow.print()
  }

  // Resolves on error as well as load, so a single broken photo cannot hang the
  // print dialog forever — a missing square is better than no passport.
  #imagesSettled(printWindow) {
    const images = Array.from(printWindow.document.images)

    return Promise.all(
      images.map((image) => {
        if (image.complete) return Promise.resolve()

        return new Promise((resolve) => {
          image.addEventListener("load", resolve, { once: true })
          image.addEventListener("error", resolve, { once: true })
        })
      })
    )
  }

  #profile() {
    try {
      const stored = localStorage.getItem(this.constructor.PROFILE_STORAGE_KEY)
      return stored ? JSON.parse(stored) : null
    } catch {
      return null
    }
  }

  #escape(value) {
    if (value === null || value === undefined) return ""

    return String(value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;")
  }

  // Machine-readable zone: two fixed-width lines of 44 chars, filler "<".
  // Decorative — it encodes the same souvenir data shown above it.
  #mrzLines() {
    const pad = (value, length) =>
      String(value)
        .toUpperCase()
        .replace(/[^A-Z0-9]/g, "<")
        .slice(0, length)
        .padEnd(length, "<")

    const holder = this.holderValue || "TRAVELLER"
    const issuedDigits = this.issuedValue.replace(/\D/g, "").slice(-6).padStart(6, "0")

    return [pad(`P<USP${holder}`, 44), pad(`${this.numberValue}<0USP${issuedDigits}`, 44)]
  }

  // Stylised shield in the passport's livery. Deliberately not the state coat of
  // arms: this is an Usput.ba souvenir, not a replica of a national document.
  #crest() {
    return `
      <svg class="crest" viewBox="0 0 60 72" aria-hidden="true">
        <path d="M30 2 L57 11 V38 C57 55 45 66 30 70 C15 66 3 55 3 38 V11 Z"
              fill="none" stroke="currentColor" stroke-width="2.5"/>
        <path d="M18 16 L44 16 L18 56 Z" fill="currentColor" opacity="0.9"/>
        <g fill="currentColor">
          <circle cx="46" cy="24" r="2.6"/>
          <circle cx="40" cy="34" r="2.6"/>
          <circle cx="34" cy="44" r="2.6"/>
          <circle cx="28" cy="54" r="2.6"/>
        </g>
      </svg>`
  }

  #documentHtml() {
    const t = this.translationsValue

    return `<!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>${this.#escape(t.passport)} - Usput.ba</title>
        <style>${this.#styles()}</style>
      </head>
      <body>
        <div class="booklet">
          ${this.#coverPage()}
          ${this.#dataPage()}
          ${this.momentsValue.map((moment, index) => this.#momentPage(moment, index)).join("")}
        </div>
      </body>
      </html>`
  }

  #styles() {
    return `
      * { margin: 0; padding: 0; box-sizing: border-box; }

      body {
        font-family: 'Inter', system-ui, -apple-system, sans-serif;
        background: #334155;
        padding: 2rem 1rem;
      }

      .booklet { display: flex; flex-wrap: wrap; gap: 1.5rem; justify-content: center; align-items: flex-start; }

      /* The real booklet size, so the popup shows something pocket-sized */
      .page {
        width: 88mm;
        height: 125mm;
        border-radius: 3mm;
        overflow: hidden;
        position: relative;
        box-shadow: 0 10px 30px rgba(0,0,0,0.35);
        flex: 0 0 auto;
      }

      /* Cover — navy and gold */
      .cover {
        background: #0d1b3e;
        color: #c9a227;
        display: flex; flex-direction: column; align-items: center; justify-content: space-between;
        padding: 9mm 6mm;
        text-align: center;
      }

      .cover-country { font-size: 2.6mm; letter-spacing: 0.28em; line-height: 2; text-transform: uppercase; }
      .cover-country strong { display: block; font-weight: 700; }
      .crest { width: 20mm; height: 24mm; }
      .cover-title { font-size: 5mm; font-weight: 800; letter-spacing: 0.3em; text-transform: uppercase; }
      .cover-sub { font-size: 2.4mm; letter-spacing: 0.2em; opacity: 0.75; margin-top: 1mm; }
      .cover-chip { font-size: 5mm; opacity: 0.8; }

      /* Inner pages — cream with a guilloche wash */
      .inner {
        background:
          repeating-radial-gradient(circle at 20% 25%, rgba(13,27,62,0.05) 0 0.6mm, transparent 0.6mm 2.2mm),
          repeating-radial-gradient(circle at 80% 75%, rgba(201,162,39,0.06) 0 0.6mm, transparent 0.6mm 2.4mm),
          #f6f3e9;
        padding: 5mm;
        display: flex;
        flex-direction: column;
      }

      .inner-header {
        display: flex; align-items: center; justify-content: space-between;
        border-bottom: 0.4mm solid #0d1b3e; padding-bottom: 1.5mm; margin-bottom: 3mm;
        color: #0d1b3e;
      }

      .inner-header-title { font-size: 2.6mm; font-weight: 800; letter-spacing: 0.2em; text-transform: uppercase; }
      .inner-header-page { font-size: 2.2mm; letter-spacing: 0.15em; opacity: 0.6; }

      /* Data page */
      .data-top { display: flex; gap: 4mm; }

      .portrait {
        width: 24mm; height: 30mm; object-fit: cover;
        border: 0.4mm solid #0d1b3e; border-radius: 1mm; background: #e2e8f0; flex: 0 0 auto;
        filter: grayscale(0.35) contrast(1.05);
      }

      .fields { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 2mm; }
      .field-label { font-size: 1.9mm; letter-spacing: 0.12em; text-transform: uppercase; color: #64748b; }
      .field-value { font-family: ui-monospace, 'JetBrains Mono', monospace; font-size: 2.9mm; font-weight: 700; color: #0d1b3e; overflow-wrap: anywhere; }

      .stats { display: flex; gap: 2mm; margin-top: 4mm; }
      .stat { flex: 1; text-align: center; border: 0.3mm solid rgba(13,27,62,0.25); border-radius: 1mm; padding: 1.5mm 0.5mm; }
      .stat-value { font-size: 4mm; font-weight: 800; color: #0d1b3e; }
      .stat-label { font-size: 1.8mm; letter-spacing: 0.08em; text-transform: uppercase; color: #64748b; margin-top: 0.5mm; }

      .mrz {
        margin-top: auto;
        font-family: ui-monospace, 'JetBrains Mono', monospace;
        font-size: 2.3mm; line-height: 1.5; letter-spacing: 0.05em;
        color: #0d1b3e;
        background: rgba(255,255,255,0.75);
        border-top: 0.3mm solid rgba(13,27,62,0.4);
        padding: 1.5mm 1mm 0;
        white-space: pre;
        overflow: hidden;
      }

      /* Moment page */
      .moment-photo {
        width: 100%;
        height: 62mm;
        object-fit: cover;
        border: 0.8mm solid white;
        border-radius: 1mm;
        box-shadow: 0 1mm 3mm rgba(13,27,62,0.25);
        background: #e2e8f0;
      }

      .moment-place { font-size: 3.4mm; font-weight: 800; color: #0d1b3e; margin-top: 3mm; }
      .moment-meta { font-size: 2.2mm; color: #64748b; margin-top: 0.5mm; }
      .moment-note { font-size: 2.3mm; color: #334155; font-style: italic; margin-top: 1.5mm; overflow: hidden; }

      .stamp {
        position: absolute; right: 5mm; bottom: 6mm;
        transform: rotate(-11deg);
        border: 0.6mm double #15803d;
        border-radius: 1mm;
        padding: 1.2mm 2.5mm;
        color: #15803d;
        text-align: center;
        opacity: 0.85;
        background: rgba(246,243,233,0.6);
      }

      .stamp-title { font-size: 2.8mm; font-weight: 800; letter-spacing: 0.18em; text-transform: uppercase; }
      .stamp-place { font-size: 1.8mm; letter-spacing: 0.1em; text-transform: uppercase; margin-top: 0.3mm; }

      @media print {
        body { background: white; padding: 0; }
        .booklet { display: block; gap: 0; }

        .page {
          box-shadow: none;
          border-radius: 0;
          page-break-after: always;
        }

        .page:last-child { page-break-after: auto; }
      }

      /* Each printed sheet is the booklet page itself, not an A4 with a card on it */
      @page { size: 88mm 125mm; margin: 0; }
    `
  }

  #coverPage() {
    const t = this.translationsValue

    return `
      <div class="page cover">
        <div class="cover-country">
          <strong>${this.#escape(t.republic)}</strong>
          ${this.#escape(t.republic_en)}
        </div>
        ${this.#crest()}
        <div>
          <div class="cover-title">${this.#escape(t.passport)}</div>
          <div class="cover-sub">${this.#escape(t.passport_en)}</div>
        </div>
        <div class="cover-chip">⬚</div>
      </div>`
  }

  #dataPage() {
    const t = this.translationsValue
    const profile = this.#profile()
    const places = new Set(this.momentsValue.map((moment) => moment.location)).size
    const trips = new Set(this.momentsValue.map((moment) => moment.trip).filter(Boolean)).size
    const portrait = this.momentsValue[0] ? this.momentsValue[0].photo : null

    return `
      <div class="page inner">
        <div class="inner-header">
          <div class="inner-header-title">${this.#escape(t.passport)}</div>
          <div class="inner-header-page">USP</div>
        </div>

        <div class="data-top">
          ${portrait ? `<img class="portrait" src="${this.#escape(portrait)}" alt="">` : `<div class="portrait"></div>`}
          <div class="fields">
            <div>
              <div class="field-label">${this.#escape(t.holder)}</div>
              <div class="field-value">${this.#escape(this.holderValue || t.traveller)}</div>
            </div>
            <div>
              <div class="field-label">${this.#escape(t.passport_number)}</div>
              <div class="field-value">${this.#escape(this.numberValue)}</div>
            </div>
            <div>
              <div class="field-label">${this.#escape(t.issued)}</div>
              <div class="field-value">${this.#escape(this.issuedValue)}</div>
            </div>
          </div>
        </div>

        <div class="stats">
          <div class="stat">
            <div class="stat-value">${places}</div>
            <div class="stat-label">${this.#escape(t.places)}</div>
          </div>
          <div class="stat">
            <div class="stat-value">${trips}</div>
            <div class="stat-label">${this.#escape(t.trips)}</div>
          </div>
          <div class="stat">
            <div class="stat-value">${this.momentsValue.length}</div>
            <div class="stat-label">${this.#escape(t.moments)}</div>
          </div>
          <div class="stat">
            <div class="stat-value">${profile ? profile.badges.length : 0}</div>
            <div class="stat-label">${this.#escape(t.badges)}</div>
          </div>
        </div>

        <div class="mrz">${this.#escape(this.#mrzLines().join("\n"))}</div>
      </div>`
  }

  #momentPage(moment, index) {
    const t = this.translationsValue
    const meta = [moment.type, moment.city].filter(Boolean).join(" · ")

    return `
      <div class="page inner">
        <div class="inner-header">
          <div class="inner-header-title">${this.#escape(t.visa)}</div>
          <div class="inner-header-page">${index + 1} / ${this.momentsValue.length}</div>
        </div>

        <img class="moment-photo" src="${this.#escape(moment.photo)}" alt="">

        <div class="moment-place">${this.#escape(moment.location)}</div>
        ${meta ? `<div class="moment-meta">${this.#escape(meta)}</div>` : ""}
        ${moment.trip ? `<div class="moment-meta">${this.#escape(t.trip)}: ${this.#escape(moment.trip)}</div>` : ""}
        ${moment.note ? `<div class="moment-note">“${this.#escape(moment.note)}”</div>` : ""}

        <div class="stamp">
          <div class="stamp-title">${this.#escape(t.visited)}</div>
          <div class="stamp-place">${this.#escape(moment.city || moment.location)}</div>
        </div>
      </div>`
  }
}
