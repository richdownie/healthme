import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hours", "notes", "result", "btn", "csrfToken"]

  async analyze() {
    const hours = this.hoursTarget.value
    const notes = this.notesTarget.value

    if (!hours) {
      this.#showResult("Enter sleep duration first.", "fair")
      return
    }

    this.btnTarget.disabled = true
    this.btnTarget.textContent = "Analyzing..."
    this.resultTarget.style.display = "none"

    try {
      const formData = new FormData()
      formData.append("hours", hours)
      formData.append("notes", notes)

      const dateInput = this.element.querySelector("[name='activity[performed_on]']")
      if (dateInput) formData.append("date", dateInput.value)

      const res = await fetch(this.element.dataset.sleepAnalyzerUrl, {
        method: "POST",
        headers: { "X-CSRF-Token": this.csrfTokenTarget.value },
        body: formData
      })

      if (!res.ok) {
        this.#showResult("Could not analyze sleep.", "fair")
        return
      }

      const data = await res.json()
      this.#showResult(data.analysis, data.quality, data.recommended_hours)
    } catch (e) {
      console.error("Sleep analysis error:", e)
      this.#showResult("Analysis failed.", "fair")
    } finally {
      this.btnTarget.disabled = false
      this.btnTarget.textContent = "Analyze"
    }
  }

  #showResult(text, quality, recommendedHours) {
    const el = this.resultTarget
    const colors = { good: "#16a34a", fair: "#d97706", poor: "#dc2626" }
    const bgs = { good: "#f0fdf4", fair: "#fffbeb", poor: "#fef2f2" }
    const borders = { good: "#bbf7d0", fair: "#fde68a", poor: "#fecaca" }
    const labels = { good: "Good Sleep", fair: "Fair Sleep", poor: "Poor Sleep" }
    const color = colors[quality] || colors.fair
    const bg = bgs[quality] || bgs.fair
    const border = borders[quality] || borders.fair
    const label = labels[quality] || "Sleep"

    let header = `<div style="color:${color}; font-weight:600; margin-bottom:4px;">${label}</div>`
    if (recommendedHours) {
      header += `<div style="font-size:12px; color:#64748b; margin-bottom:4px;">Recommended: ${recommendedHours} hrs</div>`
    }

    el.innerHTML = `${header}<div class="bp-analysis-text">${text}</div>`
    el.style.display = ""
    el.style.background = bg
    el.style.borderColor = border
    el.style.borderLeft = `3px solid ${color}`
  }
}
