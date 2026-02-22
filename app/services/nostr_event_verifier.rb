class NostrEventVerifier
  # Verify a NIP-42 signed Nostr event for authentication.
  #
  # A Nostr event's id is SHA-256 of the serialized event:
  #   [0, pubkey, created_at, kind, tags, content]
  #
  # The sig is a BIP340 Schnorr signature of the event id.
  #
  # @param signed_event [Hash] The signed event with id, pubkey, sig, kind, created_at, tags, content
  # @param expected_challenge [String] The challenge string that should be in the event tags
  # @return [Boolean]
  def self.verify(signed_event:, expected_challenge:)
    pubkey = signed_event["pubkey"]
    sig = signed_event["sig"]
    event_id = signed_event["id"]
    kind = signed_event["kind"]
    created_at = signed_event["created_at"]
    tags = signed_event["tags"]
    content = signed_event["content"]

    return false unless pubkey && sig && event_id && kind && created_at && tags && content

    # Verify kind is 22242 (NIP-42 auth)
    return false unless kind == 22242

    # Verify challenge tag exists and matches
    challenge_tag = tags.find { |t| t.is_a?(Array) && t[0] == "challenge" }
    return false unless challenge_tag && challenge_tag[1] == expected_challenge

    # Verify event id matches the serialized event hash
    serialized = [ 0, pubkey, created_at, kind, tags, content ].to_json
    expected_id = Digest::SHA256.hexdigest(serialized)
    return false unless event_id == expected_id

    # Verify Schnorr signature of the event id
    SchnorrVerifier.verify(
      message_hex: event_id,
      pubkey_hex: pubkey,
      signature_hex: sig
    )
  rescue StandardError => e
    Rails.logger.warn("Nostr event verification failed: #{e.message}")
    false
  end
end
