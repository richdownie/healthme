import { Controller } from "@hotwired/stimulus"
import "chart.js/auto"

export default class extends Controller {
  static targets = ["startDate", "endDate", "caloriesChart", "macrosChart", "exerciseChart",
                     "bpChart", "waterChart", "sleepChart", "prayerChart", "medicationChart"]
  static values = { url: String, start: String, end: String, waterGoal: Number, prayerGoal: Number, calorieGoal: Number }

  #charts = {}

  connect() {
    this.#loadData()
  }

  disconnect() {
    Object.values(this.#charts).forEach(c => c.destroy())
  }

  refresh() {
    this.startValue = this.startDateTarget.value
    this.endValue = this.endDateTarget.value
    this.#loadData()
  }

  async #loadData() {
    const url = `${this.urlValue}?start_date=${this.startValue}&end_date=${this.endValue}`
    try {
      const res = await fetch(url, { headers: { "Accept": "application/json" } })
      if (!res.ok) return
      const data = await res.json()
      this.#renderAll(data)
    } catch (e) {
      console.error("Metrics fetch error:", e)
    }
  }

  #renderAll(data) {
    const labels = data.dates.map(d => {
      const date = new Date(d + "T12:00:00")
      return date.toLocaleDateString("en-US", { month: "short", day: "numeric" })
    })

    this.#renderCalories(labels, data)
    this.#renderMacros(labels, data)
    this.#renderExercise(labels, data)
    this.#renderBP(data)
    this.#renderWater(labels, data)
    this.#renderSleep(labels, data)
    this.#renderPrayer(labels, data)
    this.#renderMedication(labels, data)
  }

  #renderCalories(labels, data) {
    const net = data.calories_in.map((v, i) => v - data.calories_burned[i])
    this.#chart("calories", this.caloriesChartTarget, {
      type: "line",
      data: {
        labels,
        datasets: [
          { label: "Consumed", data: data.calories_in, borderColor: "#2563eb", backgroundColor: "rgba(37,99,235,0.1)", fill: true, tension: 0.3 },
          { label: "Burned", data: data.calories_burned, borderColor: "#16a34a", backgroundColor: "rgba(22,163,74,0.1)", fill: true, tension: 0.3 },
          { label: "Net", data: net, borderColor: "#64748b", borderDash: [5, 5], tension: 0.3, pointRadius: 2 }
        ]
      },
      options: this.#lineOpts("cal")
    })
  }

  #renderMacros(labels, data) {
    this.#chart("macros", this.macrosChartTarget, {
      type: "bar",
      data: {
        labels,
        datasets: [
          { label: "Protein", data: data.protein, backgroundColor: "#3b82f6" },
          { label: "Carbs", data: data.carbs, backgroundColor: "#f59e0b" },
          { label: "Fat", data: data.fat, backgroundColor: "#ec4899" }
        ]
      },
      options: { ...this.#barOpts("g"), scales: { ...this.#barOpts("g").scales, x: { stacked: true }, y: { stacked: true, beginAtZero: true } } }
    })
  }

  #renderExercise(labels, data) {
    const ex = data.exercise_minutes
    this.#chart("exercise", this.exerciseChartTarget, {
      type: "bar",
      data: {
        labels,
        datasets: [
          { label: "Walk", data: ex.walk, backgroundColor: "#22c55e" },
          { label: "Run", data: ex.run, backgroundColor: "#f59e0b" },
          { label: "Weights", data: ex.weights, backgroundColor: "#ef4444" },
          { label: "Yoga", data: ex.yoga, backgroundColor: "#a855f7" }
        ]
      },
      options: { ...this.#barOpts(""), scales: { ...this.#barOpts("").scales, x: { stacked: true }, y: { stacked: true, beginAtZero: true } } }
    })
  }

  #renderBP(data) {
    const bp = data.blood_pressure
    if (bp.length === 0) {
      this.bpChartTarget.parentElement.style.display = "none"
      return
    }
    this.bpChartTarget.parentElement.style.display = ""
    const bpLabels = bp.map(r => {
      const date = new Date(r.date + "T12:00:00")
      return date.toLocaleDateString("en-US", { month: "short", day: "numeric" })
    })
    this.#chart("bp", this.bpChartTarget, {
      type: "line",
      data: {
        labels: bpLabels,
        datasets: [
          { label: "Systolic", data: bp.map(r => r.systolic), borderColor: "#dc2626", backgroundColor: "rgba(220,38,38,0.1)", fill: false, tension: 0.3 },
          { label: "Diastolic", data: bp.map(r => r.diastolic), borderColor: "#f97316", backgroundColor: "rgba(249,115,22,0.1)", fill: false, tension: 0.3 }
        ]
      },
      options: {
        ...this.#lineOpts("mmHg"),
        plugins: {
          ...this.#lineOpts("mmHg").plugins,
          annotation: undefined
        }
      }
    })
  }

  #renderWater(labels, data) {
    const goal = this.waterGoalValue
    this.#chart("water", this.waterChartTarget, {
      type: "bar",
      data: {
        labels,
        datasets: [
          { label: "Water", data: data.water_cups, backgroundColor: "#3b82f6" },
          ...(goal > 0 ? [{ label: "Goal", data: labels.map(() => goal), type: "line", borderColor: "#94a3b8", borderDash: [5, 5], pointRadius: 0, fill: false }] : [])
        ]
      },
      options: this.#barOpts("cups")
    })
  }

  #renderSleep(labels, data) {
    this.#chart("sleep", this.sleepChartTarget, {
      type: "bar",
      data: {
        labels,
        datasets: [
          { label: "Sleep", data: data.sleep_hours, backgroundColor: "#6366f1" }
        ]
      },
      options: this.#barOpts("hrs")
    })
  }

  #renderPrayer(labels, data) {
    const goal = this.prayerGoalValue
    this.#chart("prayer", this.prayerChartTarget, {
      type: "bar",
      data: {
        labels,
        datasets: [
          { label: "Prayer", data: data.prayer_minutes, backgroundColor: "#a855f7" },
          ...(goal > 0 ? [{ label: "Goal", data: labels.map(() => goal), type: "line", borderColor: "#94a3b8", borderDash: [5, 5], pointRadius: 0, fill: false }] : [])
        ]
      },
      options: this.#barOpts("min")
    })
  }

  #renderMedication(labels, data) {
    this.#chart("medication", this.medicationChartTarget, {
      type: "bar",
      data: {
        labels,
        datasets: [
          { label: "Medications / Supplements", data: data.medication_count, backgroundColor: "#14b8a6" }
        ]
      },
      options: this.#barOpts("")
    })
  }

  #chart(key, canvas, config) {
    if (this.#charts[key]) this.#charts[key].destroy()
    this.#charts[key] = new window.Chart(canvas, {
      ...config,
      options: {
        ...config.options,
        responsive: true,
        maintainAspectRatio: true,
        plugins: { ...config.options?.plugins, legend: { position: "bottom", labels: { boxWidth: 12, padding: 12 } } }
      }
    })
  }

  #lineOpts(unit) {
    return {
      scales: { y: { beginAtZero: true, ticks: { callback: v => `${v} ${unit}` } } },
      interaction: { mode: "index", intersect: false },
      plugins: { tooltip: { callbacks: { label: ctx => `${ctx.dataset.label}: ${ctx.parsed.y} ${unit}` } } }
    }
  }

  #barOpts(unit) {
    return {
      scales: { y: { beginAtZero: true, ticks: { callback: v => `${v} ${unit}` } } },
      plugins: { tooltip: { callbacks: { label: ctx => `${ctx.dataset.label}: ${ctx.parsed.y} ${unit}` } } }
    }
  }
}
