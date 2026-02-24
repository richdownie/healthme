import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["time", "inline", "lastMeal"]
  static values = { timestamp: String }

  connect() {
    if (!this.timestampValue) {
      this.element.style.display = "none"
      return
    }
    this.startTime = new Date(this.timestampValue)
    this.#update()
    this._interval = setInterval(() => this.#update(), 1000)
  }

  disconnect() {
    if (this._interval) clearInterval(this._interval)
  }

  #update() {
    const elapsed = Math.floor((Date.now() - this.startTime.getTime()) / 1000)
    const h = Math.floor(elapsed / 3600)
    const m = Math.floor((elapsed % 3600) / 60)
    const s = elapsed % 60

    const formatted = `${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`
    this.timeTarget.textContent = formatted
    if (this.hasInlineTarget) this.inlineTarget.textContent = formatted

    this.#applyMilestone(h)
  }

  #applyMilestone(hours) {
    const targets = [this.timeTarget]
    if (this.hasInlineTarget) targets.push(this.inlineTarget)

    const classes = ["fasting-milestone-12", "fasting-milestone-16", "fasting-milestone-18", "fasting-milestone-24"]
    let add = null
    if (hours >= 24) add = "fasting-milestone-24"
    else if (hours >= 18) add = "fasting-milestone-18"
    else if (hours >= 16) add = "fasting-milestone-16"
    else if (hours >= 12) add = "fasting-milestone-12"

    for (const el of targets) {
      el.classList.remove(...classes)
      if (add) el.classList.add(add)
    }
  }
}
