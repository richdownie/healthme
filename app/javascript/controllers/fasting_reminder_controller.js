import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["banner"]
  static values = {
    startHour: { type: Number, default: 20 },
    today: { type: Boolean, default: false }
  }

  connect() {
    if (!this.todayValue) return
    this.#scheduleCheck()
    this.#scheduleNotification()
  }

  disconnect() {
    if (this._timer) clearTimeout(this._timer)
    if (this._notifTimer) clearTimeout(this._notifTimer)
  }

  #scheduleCheck() {
    const now = new Date()
    const cutoff = new Date()
    cutoff.setHours(this.startHourValue, 0, 0, 0)

    if (now >= cutoff) {
      this.#showBanner()
    } else {
      this._timer = setTimeout(() => this.#showBanner(), cutoff - now)
    }
  }

  #showBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.style.display = ""
    }
  }

  enableNotifications() {
    if ("Notification" in window && Notification.permission === "default") {
      Notification.requestPermission()
    }
  }

  #scheduleNotification() {
    if (!("Notification" in window)) return

    const now = new Date()
    const cutoff = new Date()
    cutoff.setHours(this.startHourValue, 0, 0, 0)

    if (now >= cutoff) return

    this._notifTimer = setTimeout(() => {
      if (Notification.permission === "granted") {
        new Notification("Fasting Reminder", {
          body: "Time to start your fast. Only water and non-caloric fluids from now.",
          icon: "/icon.png",
          tag: "fasting-reminder"
        })
      }
    }, cutoff - now)
  }
}
