class User < ApplicationRecord
  has_many :activities, dependent: :destroy

  validates :pubkey_hex, presence: true, uniqueness: true,
            format: { with: /\A[0-9a-f]{64}\z/, message: "must be a 64-character hex string" }
  validates :npub, presence: true, uniqueness: true

  before_validation :derive_npub_from_pubkey, if: -> { pubkey_hex.present? && npub.blank? }

  def short_npub
    "#{npub[0..8]}...#{npub[-4..]}"
  end

  private

  def derive_npub_from_pubkey
    entity = Bech32::Nostr::BareEntity.new("npub", pubkey_hex)
    self.npub = entity.encode
  rescue StandardError
    errors.add(:pubkey_hex, "could not derive npub")
  end
end
