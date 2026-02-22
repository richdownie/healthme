import { Controller } from "@hotwired/stimulus"
import { bytesToHex } from "@noble/hashes/utils"
import { sha256 } from "@noble/hashes/sha256"

// NIP-07 extension detection and signing
export default class extends Controller {
  static targets = ["extensionBtn", "extensionStatus", "divider", "challengeUrl", "sessionUrl", "csrfToken"]

  connect() {
    // Check for NIP-07 extension immediately and after a delay
    this.#detectExtension()
    this.detectTimer = setTimeout(() => this.#detectExtension(), 500)
  }

  disconnect() {
    if (this.detectTimer) clearTimeout(this.detectTimer)
  }

  async signInWithExtension() {
    if (!window.nostr) {
      alert("No Nostr browser extension found. Install Alby, nos2x, or another NIP-07 extension.")
      return
    }

    this.#setStatus("Connecting to extension...")
    this.#setLoading(true)

    try {
      // Step 1: Get public key from extension (no signing prompt)
      const publicKeyHex = await window.nostr.getPublicKey()
      this.#setStatus("Requesting challenge...")

      // Step 2: Request challenge from server
      const csrfToken = this.csrfTokenTarget.value
      const challengeRes = await fetch(this.challengeUrlTarget.value, {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken },
        body: JSON.stringify({ pubkey_hex: publicKeyHex })
      })

      if (!challengeRes.ok) throw new Error("Failed to get challenge")
      const { challenge } = await challengeRes.json()

      this.#setStatus("Please approve the signing request...")

      // Step 3: Create NIP-42 auth event and sign with extension
      const event = {
        kind: 22242,
        created_at: Math.floor(Date.now() / 1000),
        tags: [["challenge", challenge]],
        content: `Authenticate to HealthMe: ${challenge}`
      }

      const signedEvent = await window.nostr.signEvent(event)

      this.#setStatus("Verifying signature...")

      // Step 4: Send signed event to server
      const sessionRes = await fetch(this.sessionUrlTarget.value, {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken },
        body: JSON.stringify({
          pubkey_hex: signedEvent.pubkey,
          challenge: challenge,
          signed_event: signedEvent
        })
      })

      const result = await sessionRes.json()

      if (result.success) {
        this.#setStatus("Signed in!")
        window.Turbo.visit(result.redirect_to)
      } else {
        this.#setStatus("")
        this.#setLoading(false)
        alert(result.error || "Authentication failed")
      }
    } catch (e) {
      console.error("Extension auth error:", e)
      this.#setStatus("")
      this.#setLoading(false)
      if (e.message?.includes("denied") || e.message?.includes("cancelled") || e.message?.includes("rejected")) {
        // User cancelled the extension prompt — no alert needed
      } else {
        alert("Extension authentication failed. Please try again.")
      }
    }
  }

  // Private

  #detectExtension() {
    if (window.nostr) {
      if (this.hasExtensionBtnTarget) this.extensionBtnTarget.style.display = ""
      if (this.hasDividerTarget) this.dividerTarget.style.display = ""
    }
  }

  #setStatus(msg) {
    if (this.hasExtensionStatusTarget) {
      this.extensionStatusTarget.textContent = msg
      this.extensionStatusTarget.style.display = msg ? "" : "none"
    }
  }

  #setLoading(loading) {
    if (this.hasExtensionBtnTarget) {
      this.extensionBtnTarget.disabled = loading
      this.extensionBtnTarget.textContent = loading ? "Connecting..." : "Sign in with Nostr Extension"
    }
  }
}
