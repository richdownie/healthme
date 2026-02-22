class Activity < ApplicationRecord
  CATEGORIES = %w[food walk run weights yoga sleep water prayer_meditation other].freeze

  belongs_to :user, optional: true
  has_many_attached :photos

  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :performed_on, presence: true

  INTAKE_CATEGORIES = %w[food water].freeze
  BURN_CATEGORIES = %w[walk run weights yoga].freeze

  scope :on_date, ->(date) { where(performed_on: date) }
  scope :recent, -> { order(performed_on: :desc, created_at: :desc) }

  def display_value
    return nil unless value
    "#{value} #{unit}".strip
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
end
