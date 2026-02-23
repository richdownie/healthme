import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["systolic", "diastolic", "result", "btn", "csrfToken"]

  async analyze() {
    const systolic = this.systolicTarget.value
    const diastolic = this.diastolicTarget.value

    if (!systolic || !diastolic) {
      this.#showResult("Enter both systolic and diastolic values first.", "medium")
      return
    }

    this.btnTarget.disabled = true
    this.btnTarget.textContent = "Analyzing..."
    this.resultTarget.style.display = "none"

    try {
      const formData = new FormData()
      formData.append("systolic", systolic)
      formData.append("diastolic", diastolic)

      const dateInput = this.element.querySelector("[name='activity[performed_on]']")
      if (dateInput) formData.append("date", dateInput.value)

      const res = await fetch(this.element.dataset.bpAnalyzerUrl, {
        method: "POST",
        headers: { "X-CSRF-Token": this.csrfTokenTarget.value },
        body: formData
      })

      if (!res.ok) {
        this.#showResult("Could not analyze reading.", "medium")
        return
      }

      const data = await res.json()
      this.#showResult(data.analysis, data.risk, data.classification)
    } catch (e) {
      console.error("BP analysis error:", e)
      this.#showResult("Analysis failed.", "medium")
    } finally {
      this.btnTarget.disabled = false
      this.btnTarget.textContent = "Analyze"
    }
  }

  #showResult(text, risk, classification) {
    const el = this.resultTarget
    const colors = { low: "#16a34a", medium: "#d97706", high: "#dc2626" }
    const bgs = { low: "#f0fdf4", medium: "#fffbeb", high: "#fef2f2" }
    const borders = { low: "#bbf7d0", medium: "#fde68a", high: "#fecaca" }
    const color = colors[risk] || colors.medium
    const bg = bgs[risk] || bgs.medium
    const border = borders[risk] || borders.medium

    let header = ""
    if (classification) {
      header = `<div class="bp-classification" style="color:${color}; font-weight:600; margin-bottom:4px;">${classification}</div>`
    }

    el.innerHTML = `${header}<div class="bp-analysis-text">${text}</div>`
    el.style.display = ""
    el.style.background = bg
    el.style.borderColor = border
    el.style.borderLeft = `3px solid ${color}`
  }
}
