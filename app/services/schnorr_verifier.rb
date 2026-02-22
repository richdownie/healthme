class SchnorrVerifier
  # Verify a BIP340 Schnorr signature.
  #
  # @param message_hex [String] 64-char hex (SHA-256 hash of the challenge)
  # @param pubkey_hex [String] 64-char hex (32-byte x-only public key)
  # @param signature_hex [String] 128-char hex (64-byte Schnorr signature)
  # @return [Boolean]
  def self.verify(message_hex:, pubkey_hex:, signature_hex:)
    message = [ message_hex ].pack("H*")
    public_key = [ pubkey_hex ].pack("H*")  # x-only, 32 bytes, no prefix
    signature = [ signature_hex ].pack("H*")

    Schnorr.valid_sig?(message, public_key, signature)
  rescue StandardError => e
    Rails.logger.warn("Schnorr verification failed: #{e.message}")
    false
  end
end
