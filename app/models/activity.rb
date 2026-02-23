class Activity < ApplicationRecord
  CATEGORIES = %w[food coffee walk run weights yoga sleep water prayer_meditation blood_pressure other].freeze

  belongs_to :user, optional: true
  has_many_attached :photos

  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :performed_on, presence: true

  INTAKE_CATEGORIES = %w[food coffee water].freeze
  BURN_CATEGORIES = %w[walk run weights yoga].freeze

  scope :on_date, ->(date) { where(performed_on: date) }
  scope :recent, -> { order(performed_on: :desc, created_at: :desc) }

  def display_value
    return nil unless value
    if category == "blood_pressure" && unit.present?
      "#{value.to_i} / #{unit}"
    else
      "#{value} #{unit}".strip
    end
  end

  def intake?
    category.in?(INTAKE_CATEGORIES)
  end

  def burn?
    category.in?(BURN_CATEGORIES)
  end

  def self.calories_intake
    where(category: INTAKE_CATEGORIES).sum(:calories)
  end

  def self.calories_burned
    where(category: BURN_CATEGORIES).sum(:calories)
  end

  def self.macro_totals
    intake = where(category: INTAKE_CATEGORIES)
    {
      protein_g: intake.sum(:protein_g).to_f.round(1),
      carbs_g:   intake.sum(:carbs_g).to_f.round(1),
      fat_g:     intake.sum(:fat_g).to_f.round(1),
      fiber_g:   intake.sum(:fiber_g).to_f.round(1),
      sugar_g:   intake.sum(:sugar_g).to_f.round(1)
    }
  end
end
