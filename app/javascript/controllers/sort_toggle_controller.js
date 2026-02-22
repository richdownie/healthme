import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["grouped", "timeline", "btn"]

  connect() {
    this.mode = "grouped"
  }

  toggle() {
    if (this.mode === "grouped") {
      this.mode = "timeline"
      this.groupedTarget.style.display = "none"
      this.timelineTarget.style.display = "block"
    } else {
      this.mode = "grouped"
      this.groupedTarget.style.display = "block"
      this.timelineTarget.style.display = "none"
    }
    this.updateButton()
  }

  updateButton() {
    if (this.mode === "grouped") {
      this.btnTarget.textContent = "Timeline"
    } else {
      this.btnTarget.textContent = "By Category"
    }
  }
}
