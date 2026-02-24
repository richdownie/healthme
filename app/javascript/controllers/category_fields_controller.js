import { Controller } from "@hotwired/stimulus"

const CATEGORY_CONFIG = {
  food: {
    valueLabel: "Amount",
    valuePlaceholder: "e.g. 1.5",
    unitMode: "select",
    unitOptions: ["servings", "oz", "cups", "pieces", "grams"],
    calorieLabel: "Calories Consumed",
    calorieHint: "Estimated calories in this food or drink",
    showCalories: true,
    notesPlaceholder: "What did you eat?",
    showPhotos: true,
    showAmount: true,
  },
  coffee: {
    valueLabel: "Amount",
    valuePlaceholder: "e.g. 20",
    unitMode: "select",
    unitOptions: ["oz", "cups", "shots"],
    calorieLabel: "Calories Consumed",
    calorieHint: "Estimated calories in this coffee",
    showCalories: true,
    notesPlaceholder: "Type of coffee, additions, etc.",
    showPhotos: true,
    showAmount: true,
  },
  walk: {
    valueLabel: "Distance",
    valuePlaceholder: "e.g. 2.5",
    unitMode: "select",
    unitOptions: ["miles", "km"],
    calorieLabel: "Calories Burned",
    calorieHint: "Estimated calories burned during this walk",
    showCalories: true,
    notesPlaceholder: "Steps, duration, or other details",
    showPhotos: false,
    showAmount: true,
  },
  run: {
    valueLabel: "Distance",
    valuePlaceholder: "e.g. 3.1",
    unitMode: "select",
    unitOptions: ["miles", "km"],
    calorieLabel: "Calories Burned",
    calorieHint: "Estimated calories burned during this run",
    showCalories: true,
    notesPlaceholder: "Duration, pace, etc.",
    showPhotos: false,
    showAmount: true,
  },
  weights: {
    valueLabel: "Duration",
    valuePlaceholder: "e.g. 45",
    unitMode: "select",
    unitOptions: ["minutes", "sets", "reps"],
    calorieLabel: "Calories Burned",
    calorieHint: "Estimated calories burned during weight training",
    showCalories: true,
    notesPlaceholder: "Exercises, weights, etc.",
    showPhotos: false,
    showAmount: true,
  },
  yoga: {
    valueLabel: "Duration",
    valuePlaceholder: "e.g. 30",
    unitMode: "fixed",
    fixedUnit: "minutes",
    calorieLabel: "Calories Burned",
    calorieHint: "Estimated calories burned during yoga",
    showCalories: true,
    notesPlaceholder: "Type of yoga, etc.",
    showPhotos: false,
    showAmount: true,
  },
  sleep: {
    valueLabel: "Duration",
    valuePlaceholder: "e.g. 7.5",
    unitMode: "fixed",
    fixedUnit: "hours",
    showCalories: false,
    notesPlaceholder: "Sleep quality, wake-ups, etc.",
    showPhotos: false,
    showAmount: true,
    showSleepAnalyze: true,
  },
  water: {
    valueLabel: "Amount",
    valuePlaceholder: "e.g. 8",
    unitMode: "select",
    unitOptions: ["cups", "oz", "ml", "liters"],
    showCalories: false,
    notesPlaceholder: "",
    showPhotos: false,
    showAmount: true,
  },
  prayer_meditation: {
    valueLabel: "Duration",
    valuePlaceholder: "e.g. 15",
    unitMode: "fixed",
    fixedUnit: "minutes",
    showCalories: false,
    notesPlaceholder: "",
    showPhotos: false,
    showAmount: true,
  },
  blood_pressure: {
    valueLabel: "Systolic",
    valuePlaceholder: "e.g. 120",
    unitMode: "bp",
    showCalories: false,
    notesPlaceholder: "Time of day, arm used, notes...",
    showPhotos: false,
    showAmount: true,
  },
  medication: {
    valueLabel: "Dose",
    valuePlaceholder: "e.g. 1000",
    unitMode: "select",
    unitOptions: ["mg", "g", "mcg", "IU", "capsules", "tablets", "softgels", "drops", "ml"],
    showCalories: false,
    notesPlaceholder: "e.g. Fish Oil, Creatine, Vitamin D...",
    showPhotos: true,
    showAmount: true,
    showMedAnalyze: true,
  },
  brush_teeth: {
    valueLabel: "Duration",
    valuePlaceholder: "e.g. 2",
    unitMode: "fixed",
    fixedUnit: "minutes",
    showCalories: false,
    notesPlaceholder: "Morning, evening, etc.",
    showPhotos: false,
    showAmount: true,
  },
  body_weight: {
    valueLabel: "Weight",
    valuePlaceholder: "e.g. 185",
    unitMode: "select",
    unitOptions: ["lbs", "kg"],
    showCalories: false,
    notesPlaceholder: "Time of day, conditions, etc.",
    showPhotos: false,
    showAmount: true,
  },
  other: {
    valueLabel: "Amount",
    valuePlaceholder: "e.g. 3.5",
    unitMode: "free",
    calorieLabel: "Calories",
    calorieHint: "Estimated calories consumed or burned",
    showCalories: true,
    notesPlaceholder: "What did you do?",
    showPhotos: true,
    showAmount: true,
  },
}

const DEFAULT_CONFIG = CATEGORY_CONFIG.other

export default class extends Controller {
  static targets = [
    "amountRow",
    "valueLabel",
    "valueField",
    "unitGroup",
    "unitSelect",
    "unitText",
    "diastolicGroup",
    "diastolicField",
    "bpAnalyzeRow",
    "medAnalyzeRow",
    "sleepAnalyzeRow",
    "calorieRow",
    "calorieLabel",
    "calorieHint",
    "notesField",
    "photosRow",
  ]

  connect() {
    this.toggle()
  }

  valueChanged() {
    this.#updateFieldLock()
  }

  toggle() {
    const select = this.element.querySelector("select[name*='category']")
    if (!select) return

    const config = CATEGORY_CONFIG[select.value] || DEFAULT_CONFIG

    // Amount row visibility
    this.amountRowTarget.style.display = config.showAmount ? "flex" : "none"

    // Value label + placeholder
    if (this.hasValueLabelTarget) {
      this.valueLabelTarget.textContent = config.valueLabel
    }
    if (this.hasValueFieldTarget) {
      this.valueFieldTarget.placeholder = config.valuePlaceholder
    }

    // Diastolic field (BP mode)
    const isBP = config.unitMode === "bp"
    if (this.hasUnitGroupTarget) {
      this.unitGroupTarget.style.display = isBP ? "none" : ""
    }
    if (this.hasDiastolicGroupTarget) {
      this.diastolicGroupTarget.style.display = isBP ? "" : "none"
      this.diastolicFieldTarget.name = isBP ? "activity[unit]" : ""
    }
    if (this.hasBpAnalyzeRowTarget) {
      this.bpAnalyzeRowTarget.style.display = isBP ? "" : "none"
    }
    if (this.hasMedAnalyzeRowTarget) {
      this.medAnalyzeRowTarget.style.display = config.showMedAnalyze ? "" : "none"
    }
    if (this.hasSleepAnalyzeRowTarget) {
      this.sleepAnalyzeRowTarget.style.display = config.showSleepAnalyze ? "" : "none"
    }

    // Unit: select vs fixed vs free text
    if (this.hasUnitSelectTarget && this.hasUnitTextTarget) {
      if (config.unitMode === "bp") {
        this.unitSelectTarget.style.display = "none"
        this.unitTextTarget.style.display = "none"
        this.unitSelectTarget.name = ""
        this.unitTextTarget.name = ""
      } else if (config.unitMode === "select") {
        this.unitSelectTarget.style.display = ""
        this.unitTextTarget.style.display = "none"
        this.unitTextTarget.name = ""
        this.unitSelectTarget.name = "activity[unit]"
        this.#rebuildUnitOptions(config.unitOptions)
      } else if (config.unitMode === "fixed") {
        this.unitSelectTarget.style.display = "none"
        this.unitTextTarget.style.display = ""
        this.unitTextTarget.name = "activity[unit]"
        this.unitSelectTarget.name = ""
        this.unitTextTarget.value = config.fixedUnit
        this.unitTextTarget.readOnly = true
      } else {
        // free text
        this.unitSelectTarget.style.display = "none"
        this.unitTextTarget.style.display = ""
        this.unitTextTarget.name = "activity[unit]"
        this.unitSelectTarget.name = ""
        if (this.unitTextTarget.readOnly) {
          this.unitTextTarget.value = ""
        }
        this.unitTextTarget.readOnly = false
        this.unitTextTarget.placeholder = "e.g. miles, reps, oz"
      }
    }

    // Calories section
    if (this.hasCalorieRowTarget) {
      this.calorieRowTarget.style.display = config.showCalories ? "" : "none"
      if (!config.showCalories) {
        const calorieInput = this.calorieRowTarget.querySelector("input[type='number']")
        if (calorieInput) calorieInput.value = ""
      }
    }
    if (this.hasCalorieLabelTarget && config.calorieLabel) {
      this.calorieLabelTarget.textContent = config.calorieLabel
    }
    if (this.hasCalorieHintTarget) {
      this.calorieHintTarget.textContent = config.calorieHint || ""
    }

    // Notes placeholder
    if (this.hasNotesFieldTarget) {
      this.notesFieldTarget.placeholder = config.notesPlaceholder
    }

    // Photos section
    if (this.hasPhotosRowTarget) {
      this.photosRowTarget.style.display = config.showPhotos ? "" : "none"
    }

    this.#updateFieldLock()
  }

  #updateFieldLock() {
    const select = this.element.querySelector("select[name*='category']")
    if (!select) return

    const config = CATEGORY_CONFIG[select.value]
    const needsAmount = config && ["food", "coffee"].includes(select.value)
    const hasAmount = this.hasValueFieldTarget && this.valueFieldTarget.value.trim() !== ""
    const locked = needsAmount && !hasAmount

    if (this.hasCalorieRowTarget) {
      this.calorieRowTarget.querySelectorAll("input, button").forEach(el => el.disabled = locked)
    }
    if (this.hasNotesFieldTarget) this.notesFieldTarget.disabled = locked
    if (this.hasPhotosRowTarget) {
      this.photosRowTarget.querySelectorAll("input").forEach(el => el.disabled = locked)
    }
  }

  #rebuildUnitOptions(options) {
    const select = this.unitSelectTarget
    const currentValue = select.value
    select.innerHTML = ""
    options.forEach(opt => {
      const el = document.createElement("option")
      el.value = opt
      el.textContent = opt
      select.appendChild(el)
    })
    // Preserve existing value if it's in the new options (for edit form)
    if (options.includes(currentValue)) {
      select.value = currentValue
    }
  }
}
