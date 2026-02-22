import { Controller } from "@hotwired/stimulus"

const BURN_CATEGORIES = ["walk", "run", "weights", "yoga"]

export default class extends Controller {
  static targets = ["amountRow", "calorieLabel", "calorieHint"]

  connect() {
    this.toggle()
  }

  toggle() {
    const category = this.element.querySelector("select[name*='category']")
    if (!category) return

    const value = category.value
    const isBurn = BURN_CATEGORIES.includes(value)

    this.amountRowTarget.style.display = value === "walk" ? "none" : "flex"

    if (this.hasCalorieLabelTarget) {
      this.calorieLabelTarget.textContent = isBurn ? "Calories Burned" : "Calories Consumed"
    }
    if (this.hasCalorieHintTarget) {
      this.calorieHintTarget.textContent = isBurn
        ? "Estimated calories burned during this exercise"
        : "Estimated calories in this food or drink"
    }
  }
}
