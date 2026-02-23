import { Controller } from "@hotwired/stimulus"

// Biometric app lock — only active inside Capacitor native shell.
// Uses custom BiometricAuth plugin (Swift LAContext wrapper) and
// capacitor-secure-storage-plugin to persist the enabled flag.
export default class extends Controller {
  static targets = ["overlay", "retryButton", "toggle", "toggleSection"]

  connect() {
    if (!this.isNative) return

    this.showToggleSection()

    // Always load setting to update toggle UI
    this.loadSetting().then((enabled) => {
      // Only lock on fresh app launch, not on Turbo navigations
      if (enabled && !window._biometricUnlocked) this.lock()
    })

    // Register appStateChange listener once globally
    if (!window._biometricListenerRegistered) {
      window._biometricListenerRegistered = true
      const { App } = window.Capacitor.Plugins
      if (App) {
        App.addListener("appStateChange", ({ isActive }) => {
          if (!isActive) {
            window._biometricWentToBackground = true
          } else if (window._biometricWentToBackground) {
            window._biometricWentToBackground = false
            // Face ID dismiss triggers isActive false→true within ~1s.
            // Ignore state changes within 3s of a successful unlock.
            const timeSinceUnlock = Date.now() - (window._biometricUnlockTime || 0)
            if (timeSinceUnlock < 3000) return
            window._biometricUnlocked = false
            this.loadSetting().then((enabled) => {
              if (enabled) this.lock()
            })
          }
        })
      }
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
    if (this._authenticating) return
    if (this.hasOverlayTarget) {
      this.overlayTarget.style.display = "flex"
    }
    this.authenticate()
  }

  unlock() {
    window._biometricUnlocked = true
    window._biometricUnlockTime = Date.now()
    if (this.hasOverlayTarget) {
      this.overlayTarget.style.display = "none"
    }
  }

  async authenticate() {
    if (this._authenticating) return
    this._authenticating = true
    try {
      await this.biometric.authenticate({ reason: "Unlock HealthMe" })
      this.unlock()
    } catch {
      // Show retry button on failure
      if (this.hasRetryButtonTarget) {
        this.retryButtonTarget.style.display = "inline-block"
      }
    } finally {
      this._authenticating = false
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
        // Mark as unlocked so we don't immediately lock after enabling
        window._biometricUnlocked = true
        window._biometricUnlockTime = Date.now()
      } catch {
        this.toggleTarget.checked = false
      }
    } else {
      await this.storage.set({ key: "biometric_enabled", value: "false" })
      // Remove stored key so user must sign in manually next time
      try { await this.storage.remove({ key: "stored_nsec" }) } catch { /* key may not exist */ }
    }
  }

  // --- Visibility ---

  showToggleSection() {
    if (this.hasToggleSectionTarget) {
      this.toggleSectionTarget.style.display = "block"
    }
  }
}
