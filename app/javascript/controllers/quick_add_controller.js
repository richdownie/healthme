import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "input"]

  reveal() {
    this.formTarget.style.display = "flex"
    this.inputTarget.value = ""
    this.inputTarget.focus()
  }

  confirmAdd() {
    const val = parseFloat(this.inputTarget.value)
    if (val > 0) {
      this.formTarget.requestSubmit()
    }
  }

  cancel() {
    this.formTarget.style.display = "none"
  }

  inputKeydown(e) {
    if (e.key === "Enter") {
      e.preventDefault()
      this.confirmAdd()
    } else if (e.key === "Escape") {
      this.cancel()
    }
  }
}
