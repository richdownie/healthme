class User < ApplicationRecord
  has_many :activities, dependent: :destroy

  SEXES = %w[male female other].freeze
  ACTIVITY_LEVELS = %w[sedentary lightly_active moderately_active very_active extra_active].freeze
  GOALS = %w[lose_weight maintain gain_muscle].freeze

  validates :pubkey_hex, presence: true, uniqueness: true,
            format: { with: /\A[0-9a-f]{64}\z/, message: "must be a 64-character hex string" }
  validates :npub, presence: true, uniqueness: true

  validates :weight, numericality: { greater_than: 0, less_than: 1000 }, allow_nil: true
  validates :height, numericality: { greater_than: 0, less_than: 120 }, allow_nil: true
  validates :sex, inclusion: { in: SEXES }, allow_nil: true
  validates :activity_level, inclusion: { in: ACTIVITY_LEVELS }, allow_nil: true
  validates :goal, inclusion: { in: GOALS }, allow_nil: true
  validates :blood_pressure_systolic, numericality: { in: 60..250 }, allow_nil: true
  validates :blood_pressure_diastolic, numericality: { in: 30..150 }, allow_nil: true
  validate :blood_pressure_pair

  before_validation :derive_npub_from_pubkey, if: -> { pubkey_hex.present? && npub.blank? }

  def short_npub
    "#{npub[0..8]}...#{npub[-4..]}"
  end

  def profile_complete?
    weight.present? && height.present? && date_of_birth.present? && sex.present?
  end

  def age
    return nil unless date_of_birth
    today = Date.today
    age = today.year - date_of_birth.year
    age -= 1 if today < date_of_birth + age.years
    age
  end

  def recommendations
    @recommendations ||= HealthCalculator.new(self).calculate
  end

  private

  def derive_npub_from_pubkey
    entity = Bech32::Nostr::BareEntity.new("npub", pubkey_hex)
    self.npub = entity.encode
  rescue StandardError
    errors.add(:pubkey_hex, "could not derive npub")
  end

  def blood_pressure_pair
    if blood_pressure_systolic.present? ^ blood_pressure_diastolic.present?
      errors.add(:base, "Both systolic and diastolic blood pressure must be provided together")
    end
  end
end
