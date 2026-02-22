import { Controller } from "@hotwired/stimulus"
import { schnorr } from "@noble/curves/secp256k1"
import { sha256 } from "@noble/hashes/sha256"
import { bytesToHex, hexToBytes } from "@noble/hashes/utils"

export default class extends Controller {
  static targets = ["pubkeyHex", "secretKey", "challengeUrl", "sessionUrl", "csrfToken"]

  async signIn() {
    const pubkeyHex = this.pubkeyHexTarget.value
    const secretHex = this.secretKeyTarget.value
    const csrfToken = this.csrfTokenTarget.value

    if (!pubkeyHex || !secretHex) {
      alert("Please generate or enter a keypair first.")
      return
    }

    try {
      // Step 1: Request challenge from server
      const challengeRes = await fetch(this.challengeUrlTarget.value, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken
        },
        body: JSON.stringify({ pubkey_hex: pubkeyHex })
      })

      if (!challengeRes.ok) throw new Error("Failed to get challenge")
      const { challenge } = await challengeRes.json()

      // Step 2: Hash the challenge with SHA-256
      const encoder = new TextEncoder()
      const challengeBytes = encoder.encode(challenge)
      const messageHash = sha256(challengeBytes)
      const messageHashHex = bytesToHex(messageHash)

      // Step 3: Sign the hash with Schnorr
      const secretKey = hexToBytes(secretHex)
      const signature = await schnorr.sign(messageHash, secretKey)
      const signatureHex = bytesToHex(signature)

      // Step 4: Send signature to server for verification
      const sessionRes = await fetch(this.sessionUrlTarget.value, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken
        },
        body: JSON.stringify({
          pubkey_hex: pubkeyHex,
          signature: signatureHex,
          challenge: challenge,
          message_hash: messageHashHex
        })
      })

      const result = await sessionRes.json()

      if (result.success) {
        window.Turbo.visit(result.redirect_to)
      } else {
        alert(result.error || "Authentication failed")
      }
    } catch (e) {
      console.error("Auth error:", e)
      alert("Authentication failed. Please try again.")
    }
  }
}
