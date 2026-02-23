import { Controller } from "@hotwired/stimulus"

// Biometric app lock — only active inside Capacitor native shell.
// Uses custom BiometricAuth plugin (Swift LAContext wrapper) and
// capacitor-secure-storage-plugin to persist the enabled flag.
export default class extends Controller {
  static targets = ["overlay", "retryButton", "toggle", "toggleSection"]

  connect() {
    if (!this.isNative) return

    this.showToggleSection()
    this.loadSetting().then((enabled) => {
      if (enabled) this.lock()
    })

    // Re-lock when app resumes from background
    const { App } = window.Capacitor.Plugins
    if (App) {
      App.addListener("appStateChange", ({ isActive }) => {
        if (isActive) {
          this.loadSetting().then((enabled) => {
            if (enabled) this.lock()
          })
        }
      })
    }
  }

  get isNative() {
    return window.Capacitor && window.Capacitor.isNativePlatform()
  }

  get storage() {
    return window.Capacitor.Plugins.SecureStoragePlugin
  }

  get biometric() {
    return window.Capacitor.Plugins.BiometricAuth
  }

  // --- Lock / Unlock ---

  lock() {
    if (this.hasOverlayTarget) {
      this.overlayTarget.style.display = "flex"
    }
    this.authenticate()
  }

  unlock() {
    if (this.hasOverlayTarget) {
      this.overlayTarget.style.display = "none"
    }
  }

  async authenticate() {
    try {
      await this.biometric.authenticate({ reason: "Unlock HealthMe" })
      this.unlock()
    } catch {
      // Show retry button on failure
      if (this.hasRetryButtonTarget) {
        this.retryButtonTarget.style.display = "inline-block"
      }
    }
  }

  retry() {
    if (this.hasRetryButtonTarget) {
      this.retryButtonTarget.style.display = "none"
    }
    this.authenticate()
  }

  // --- Settings ---

  async loadSetting() {
    try {
      const { value } = await this.storage.get({ key: "biometric_enabled" })
      const enabled = value === "true"
      if (this.hasToggleTarget) this.toggleTarget.checked = enabled
      return enabled
    } catch {
      // Key not found — default to disabled
      if (this.hasToggleTarget) this.toggleTarget.checked = false
      return false
    }
  }

  async toggleBiometric() {
    const enabled = this.toggleTarget.checked

    if (enabled) {
      // Verify biometric works before enabling
      try {
        const { available } = await this.biometric.isAvailable()
        if (!available) {
          this.toggleTarget.checked = false
          alert("Biometric authentication is not available on this device.")
          return
        }
        await this.biometric.authenticate({ reason: "Enable biometric lock" })
        await this.storage.set({ key: "biometric_enabled", value: "true" })
      } catch {
        this.toggleTarget.checked = false
      }
    } else {
      await this.storage.set({ key: "biometric_enabled", value: "false" })
    }
  }

  // --- Visibility ---

  showToggleSection() {
    if (this.hasToggleSectionTarget) {
      this.toggleSectionTarget.style.display = "block"
    }
  }
}
