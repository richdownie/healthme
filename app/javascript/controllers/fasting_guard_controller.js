import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    fasting: { type: Boolean, default: false },
    startHour: { type: Number, default: 20 }
  }

  checkSubmit(event) {
    const now = new Date()
    const isFasting = now.getHours() >= this.startHourValue

    if (!isFasting) return

    const category = this.element.querySelector("select[name*='category']")
    if (!category || category.value !== "food") return

    if (!confirm("You're in your fasting window. Are you sure you want to log food?")) {
      event.preventDefault()
    }
  }
}
