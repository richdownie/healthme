class SessionsController < ApplicationController
  skip_before_action :require_authentication, only: [ :new, :challenge, :create ]

  def new
    redirect_to root_path if signed_in?
  end

  def challenge
    auth_challenge = KeypairAuthChallenge.create!(
      pubkey_hex: params[:pubkey_hex].presence
    )

    render json: {
      challenge: auth_challenge.challenge,
      expires_at: auth_challenge.expires_at.iso8601
    }
  end

  def create
    if params[:signed_event].present?
      create_from_nostr_event
    else
      create_from_raw_signature
    end
  end

  def destroy
    clear_current_user
    redirect_to new_session_path, notice: "Signed out."
  end

  private

  # NIP-07 extension flow: verify a signed Nostr event
  def create_from_nostr_event
    signed_event = params[:signed_event].to_unsafe_h
    challenge_value = params[:challenge]
    pubkey_hex = params[:pubkey_hex]&.downcase

    auth_challenge = KeypairAuthChallenge.active.find_by(challenge: challenge_value)

    unless auth_challenge&.valid_for_use?
      return render json: { error: "Invalid or expired challenge" }, status: :unprocessable_entity
    end

    if auth_challenge.pubkey_hex.present? && auth_challenge.pubkey_hex != pubkey_hex
      return render json: { error: "Challenge pubkey mismatch" }, status: :unprocessable_entity
    end

    unless NostrEventVerifier.verify(signed_event: signed_event, expected_challenge: challenge_value)
      return render json: { error: "Invalid signature" }, status: :unprocessable_entity
    end

    auth_challenge.consume!

    user = User.find_or_create_by!(pubkey_hex: pubkey_hex)
    set_current_user(user)

    render json: { success: true, redirect_to: root_path }
  end

  # Raw keypair flow: verify a Schnorr signature directly
  def create_from_raw_signature
    pubkey_hex = params[:pubkey_hex]&.downcase
    signature_hex = params[:signature]
    challenge_value = params[:challenge]
    message_hash = params[:message_hash]

    auth_challenge = KeypairAuthChallenge.active.find_by(challenge: challenge_value)

    unless auth_challenge&.valid_for_use?
      return render json: { error: "Invalid or expired challenge" }, status: :unprocessable_entity
    end

    if auth_challenge.pubkey_hex.present? && auth_challenge.pubkey_hex != pubkey_hex
      return render json: { error: "Challenge pubkey mismatch" }, status: :unprocessable_entity
    end

    expected_hash = Digest::SHA256.hexdigest(challenge_value)
    unless expected_hash == message_hash
      return render json: { error: "Message hash mismatch" }, status: :unprocessable_entity
    end

    unless SchnorrVerifier.verify(
      message_hex: message_hash,
      pubkey_hex: pubkey_hex,
      signature_hex: signature_hex
    )
      return render json: { error: "Invalid signature" }, status: :unprocessable_entity
    end

    auth_challenge.consume!

    user = User.find_or_create_by!(pubkey_hex: pubkey_hex)
    set_current_user(user)

    render json: { success: true, redirect_to: root_path }
  end
end
