import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["photo", "notes", "calories", "category", "value", "unit", "status", "csrfToken"]

  // Track whether calories were auto-filled (so we don't overwrite manual edits)
  #autoFilled = false

  connect() {
    this.caloriesTarget.addEventListener("input", () => { this.#autoFilled = false })
  }

  photoChanged() {
    if (this.photoTarget.files.length === 0) return
    this.#estimate()
  }

  notesChanged() {
    if (this.photoTarget.files.length > 0) return
    if (this.notesTarget.value.trim().length < 3) return
    this.#estimate()
  }

  estimateClicked() {
    // Force estimate regardless of current state
    this.#autoFilled = true
    this.#estimate(true)
  }

  async #estimate(force = false) {
    // Only auto-fill if calories field is empty, was auto-filled, or forced
    if (!force && this.caloriesTarget.value && !this.#autoFilled) return

    const formData = new FormData()
    const files = this.photoTarget.files
    for (let i = 0; i < files.length; i++) {
      formData.append("photos[]", files[i])
    }
    if (this.notesTarget.value) formData.append("notes", this.notesTarget.value)
    if (this.categoryTarget.value) formData.append("category", this.categoryTarget.value)
    if (this.hasValueTarget && this.valueTarget.value) formData.append("value", this.valueTarget.value)
    if (this.hasUnitTarget && this.unitTarget.value) formData.append("unit", this.unitTarget.value)

    this.#setStatus("Estimating calories...")

    try {
      const res = await fetch(this.element.dataset.estimateUrl, {
        method: "POST",
        headers: { "X-CSRF-Token": this.csrfTokenTarget.value },
        body: formData
      })

      if (!res.ok) {
        this.#setStatus("Could not estimate calories")
        return
      }

      const data = await res.json()

      if (data.calories) {
        this.caloriesTarget.value = data.calories
        this.#autoFilled = true
        this.#setStatus(data.description || `~${data.calories} cal estimated`)
      } else {
        this.#setStatus("Could not estimate calories")
      }
    } catch (e) {
      console.error("Calorie estimation error:", e)
      this.#setStatus("Estimation failed")
    }
  }

  #setStatus(msg) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = msg
      this.statusTarget.style.display = msg ? "" : "none"
    }
  }
}
