import { Controller } from "@hotwired/stimulus"
import { schnorr } from "@noble/curves/secp256k1"
import { sha256 } from "@noble/hashes/sha256"
import { bytesToHex, hexToBytes } from "@noble/hashes/utils"
import { bech32 } from "@scure/base"

// Face ID sign-in for native iOS app.
// Stores nsec in SecureStorage on successful sign-in,
// then offers one-tap Face ID sign-in on return visits.
export default class extends Controller {
  static targets = ["button", "section"]

  connect() {
    if (!this.isNative) return
    this.checkStoredKey()
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

  async checkStoredKey() {
    try {
      const { value } = await this.storage.get({ key: "stored_nsec" })
      if (value) {
        if (this.hasSectionTarget) this.sectionTarget.style.display = ""
      }
    } catch {
      // No stored key — keep button hidden
    }
  }

  async signInWithFaceId() {
    if (this.hasButtonTarget) this.buttonTarget.disabled = true

    try {
      // Step 1: Authenticate with Face ID
      await this.biometric.authenticate({ reason: "Sign in to HealthMe" })

      // Step 2: Retrieve stored nsec
      const { value: secretHex } = await this.storage.get({ key: "stored_nsec" })
      if (!secretHex) {
        alert("No stored key found. Please sign in manually.")
        return
      }

      // Step 3: Derive pubkey
      const secretKey = hexToBytes(secretHex)
      const pubkeyBytes = schnorr.getPublicKey(secretKey)
      const pubkeyHex = bytesToHex(pubkeyBytes)

      // Step 4: Get challenge
      const csrfToken = document.querySelector("[data-auth-target='csrfToken']").value
      const challengeUrl = document.querySelector("[data-auth-target='challengeUrl']").value
      const sessionUrl = document.querySelector("[data-auth-target='sessionUrl']").value

      const challengeRes = await fetch(challengeUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken },
        body: JSON.stringify({ pubkey_hex: pubkeyHex })
      })
      if (!challengeRes.ok) throw new Error("Failed to get challenge")
      const { challenge } = await challengeRes.json()

      // Step 5: Sign challenge
      const messageHash = sha256(new TextEncoder().encode(challenge))
      const signature = await schnorr.sign(messageHash, secretKey)

      // Step 6: Submit signature
      const sessionRes = await fetch(sessionUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken },
        body: JSON.stringify({
          pubkey_hex: pubkeyHex,
          signature: bytesToHex(signature),
          challenge: challenge,
          message_hash: bytesToHex(messageHash)
        })
      })

      const result = await sessionRes.json()
      if (result.success) {
        window.Turbo.visit(result.redirect_to)
      } else {
        alert(result.error || "Authentication failed")
      }
    } catch (e) {
      if (e.message && e.message.includes("cancel")) {
        // User cancelled Face ID — do nothing
      } else {
        console.error("Face ID auth error:", e)
        alert("Authentication failed. Please try again.")
      }
    } finally {
      if (this.hasButtonTarget) this.buttonTarget.disabled = false
    }
  }

  // Called after a successful manual sign-in to store the nsec
  static async storeKey(secretHex) {
    if (!window.Capacitor || !window.Capacitor.isNativePlatform()) return
    try {
      const storage = window.Capacitor.Plugins.SecureStoragePlugin
      await storage.set({ key: "stored_nsec", value: secretHex })
    } catch (e) {
      console.error("Failed to store key:", e)
    }
  }
}
