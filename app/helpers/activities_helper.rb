module ActivitiesHelper
  CATEGORY_ICONS = {
    "food" => "🍽️",
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

  def activity_tag_label(activity)
    parts = [category_icon(activity.category)]
    if activity.notes.present?
      parts << activity.notes.truncate(30)
    elsif activity.display_value
      parts << "#{activity.category.capitalize} #{activity.display_value}"
    else
      parts << activity.category.capitalize
    end
    if activity.calories.present? && activity.calories > 0
      parts << "(#{activity.calories} cal)"
    end
    parts.join(" ")
  end
end
