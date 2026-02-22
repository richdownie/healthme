module ActivitiesHelper
  CATEGORY_ICONS = {
    "meal" => "🍽️",
    "walk" => "🚶",
    "run" => "🏃",
    "pushups" => "💪",
    "exercise" => "🏋️",
    "sleep" => "😴",
    "water" => "💧",
    "weight" => "⚖️",
    "other" => "📝"
  }.freeze

  def category_icon(category)
    CATEGORY_ICONS[category] || "📝"
  end
end
