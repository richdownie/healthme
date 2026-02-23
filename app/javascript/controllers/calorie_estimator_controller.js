import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["photo", "notes", "calories", "category", "value", "status", "csrfToken",
                     "proteinG", "carbsG", "fatG", "fiberG", "sugarG", "riskMeter", "estimateBtn"]

  // Track whether calories were auto-filled (so we don't overwrite manual edits)
  #autoFilled = false

  connect() {
    this.caloriesTarget.addEventListener("input", () => { this.#autoFilled = false })
    this.#updateEstimateBtn()
  }

  valueChanged() {
    this.#updateEstimateBtn()
  }

  #updateEstimateBtn() {
    if (!this.hasEstimateBtnTarget || !this.hasValueTarget) return
    this.estimateBtnTarget.disabled = this.valueTarget.value.trim() === ""
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
    const unitInput = this.element.querySelector("[name='activity[unit]']")
    if (unitInput && unitInput.value) formData.append("unit", unitInput.value)

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

        // Populate nutrient hidden fields
        if (this.hasProteinGTarget) this.proteinGTarget.value = data.protein_g ?? ""
        if (this.hasCarbsGTarget)   this.carbsGTarget.value   = data.carbs_g ?? ""
        if (this.hasFatGTarget)     this.fatGTarget.value     = data.fat_g ?? ""
        if (this.hasFiberGTarget)   this.fiberGTarget.value   = data.fiber_g ?? ""
        if (this.hasSugarGTarget)   this.sugarGTarget.value   = data.sugar_g ?? ""

        const macros = [
          data.protein_g ? `Protein: ${data.protein_g}g` : null,
          data.carbs_g ? `Carbs: ${data.carbs_g}g` : null,
          data.fat_g ? `Fat: ${data.fat_g}g` : null
        ].filter(Boolean).join(" | ")

        const desc = data.description || `~${data.calories} cal estimated`
        this.#setStatus(macros ? `${desc} (${macros})` : desc)
        this.#setRisk(data.health_risk, data.health_risk_reason)
      } else {
        this.#setStatus("Could not estimate calories")
        this.#setRisk(null)
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

  #setRisk(level, reason) {
    if (!this.hasRiskMeterTarget) return
    const el = this.riskMeterTarget
    if (!level) {
      el.style.display = "none"
      return
    }
    const colors = { low: "#16a34a", medium: "#d97706", high: "#dc2626" }
    const labels = { low: "Low Risk", medium: "Moderate Risk", high: "High Risk" }
    const dots = { low: 1, medium: 2, high: 3 }
    const count = dots[level] || 1
    const color = colors[level] || colors.low

    el.innerHTML = `<span class="risk-dots">${"●".repeat(count)}<span style="color:#d1d5db">${"●".repeat(3 - count)}</span></span> <span class="risk-label" style="color:${color}">${labels[level] || level}</span>${reason ? ` <span class="risk-reason">— ${reason}</span>` : ""}`
    el.style.display = ""
  }
}
