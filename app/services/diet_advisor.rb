require "net/http"

class DietAdvisor
  API_URL = "https://api.anthropic.com/v1/messages"
  MODEL = "claude-haiku-4-5-20251001"

  # Generate personalized diet tips based on user profile and today's food log.
  #
  # @param user [User] the user
  # @param activities [Array<Activity>] today's activities
  # @param recommendations [Hash, nil] from HealthCalculator
  # @return [String, nil] markdown-formatted tips or nil
  def self.advise(user:, activities:, recommendations:, last_food_at: nil, question: nil)
    api_key = ENV["ANTHROPIC_API_KEY"]
    return nil unless api_key.present?
    return nil unless user.profile_complete?

    prompt = build_prompt(user, activities, recommendations, last_food_at, question)
    response = call_api(api_key, prompt)
    parse_response(response)
  rescue StandardError => e
    Rails.logger.warn("DietAdvisor error: #{e.message}")
    nil
  end

  private_class_method def self.build_prompt(user, activities, recs, last_food_at, question)
    food_log = activities.select { |a| a.category == "food" }.map do |a|
      parts = []
      parts << "#{a.value} #{a.unit}" if a.value.present?
      parts << a.notes if a.notes.present?
      parts << "(#{a.calories} cal)" if a.calories.present? && a.calories > 0
      parts.join(" — ")
    end

    coffee_log = activities.select { |a| a.category == "coffee" }.map do |a|
      parts = []
      parts << "#{a.value} #{a.unit}" if a.value.present?
      parts << a.notes if a.notes.present?
      parts << "(#{a.calories} cal)" if a.calories.present? && a.calories > 0
      parts.join(" — ")
    end

    water_cups = activities.select { |a| a.category == "water" }.sum(&:value)

    exercise = activities.select { |a| a.category.in?(Activity::BURN_CATEGORIES) }.map do |a|
      "#{a.category.humanize}: #{a.display_value}#{" — #{a.calories} cal burned" if a.calories.to_i > 0}#{" — #{a.notes}" if a.notes.present?}"
    end

    sleep_log = activities.select { |a| a.category == "sleep" }.map do |a|
      "#{a.value} #{a.unit}#{" — #{a.notes}" if a.notes.present?}"
    end

    bp_log = activities.select { |a| a.category == "blood_pressure" }.map do |a|
      "#{a.display_value}#{" — #{a.notes}" if a.notes.present?}"
    end

    med_log = activities.select { |a| a.category == "medication" }.map do |a|
      "#{a.notes.presence || 'Unknown'}: #{a.display_value}"
    end

    prayer_log = activities.select { |a| a.category == "prayer_meditation" }.map do |a|
      "#{a.value} #{a.unit}#{" — #{a.notes}" if a.notes.present?}"
    end

    weight_log = activities.select { |a| a.category == "body_weight" }.map do |a|
      "#{a.display_value}#{" — #{a.notes}" if a.notes.present?}"
    end

    calories_in = activities.select(&:intake?).sum { |a| a.calories.to_i }
    calories_burned = activities.select(&:burn?).sum { |a| a.calories.to_i }

    profile = <<~PROF
      Age: #{user.age}, Sex: #{user.sex}, Weight: #{user.weight} lbs, Height: #{user.height} inches
      BMI: #{recs&.dig(:bmi) || 'unknown'} (#{recs&.dig(:bmi_category) || 'unknown'})
      Blood pressure: #{user.blood_pressure_systolic || '?'}/#{user.blood_pressure_diastolic || '?'} mmHg
      Activity level: #{user.activity_level&.humanize || 'unknown'}
      Goal: #{user.goal&.humanize || 'unknown'}
      Health concerns: #{user.health_concerns.presence || 'none noted'}
    PROF

    targets = if recs
      <<~TARG
        Daily calorie target: #{recs[:daily_calories]} cal
        Protein target: #{recs[:protein_g]}g, Carbs: #{recs[:carbs_g]}g, Fat: #{recs[:fat_g]}g
        Water goal: #{user.effective_water_goal} cups
        Exercise goal: #{recs[:activity_burn]} cal
        Prayer/Meditation goal: #{user.prayer_goal_minutes || 5} min
      TARG
    else
      "No calculated targets available."
    end

    <<~PROMPT
      You are a helpful daily wellness advisor. Based on this user's profile and ALL of today's logged activities, provide personalized tips covering their whole day — not just diet.

      ## User Profile
      #{profile}
      ## Daily Targets
      #{targets}
      ## Today's Activities

      **Food:** #{food_log.any? ? food_log.join("; ") : "None logged."}
      **Coffee:** #{coffee_log.any? ? coffee_log.join("; ") : "None logged."}
      **Water:** #{water_cups.round(1)} cups
      **Exercise:** #{exercise.any? ? exercise.join("; ") : "None logged."}
      **Sleep:** #{sleep_log.any? ? sleep_log.join("; ") : "Not logged."}
      **Blood Pressure:** #{bp_log.any? ? bp_log.join("; ") : "Not logged today."}
      **Medications/Supplements:** #{med_log.any? ? med_log.join("; ") : "None logged."}
      **Prayer/Meditation:** #{prayer_log.any? ? prayer_log.join("; ") : "None logged."}
      **Body Weight:** #{weight_log.any? ? weight_log.join("; ") : "Not logged today."}
      **Fasting:** #{last_food_at ? "#{((Time.current - last_food_at) / 1.hour).round(1)} hours since last food/coffee (last ate at #{last_food_at.in_time_zone.strftime("%-I:%M %p")})" : "No food logged yet."}

      Calories consumed so far: #{calories_in} cal
      Calories burned from exercise: #{calories_burned} cal

      ## Instructions
      - Give 4-6 short, specific, actionable tips based on ALL logged activities and their health profile
      - Address each area that has activity logged (sleep quality, exercise, nutrition, hydration, weight trends, medication timing, etc.)
      - For areas with no activity logged, suggest what they should do today
      - Consider their BMI, blood pressure, goal, and health concerns
      - If they have high blood pressure, mention sodium awareness
      - If they are fasting (hours since last food), acknowledge it and give relevant fasting tips (when to break fast, what to eat first, hydration)
      - Keep each tip to 1-2 sentences
      - Use a friendly, encouraging tone
      - Format as a simple numbered list (1. 2. 3.)
      - Do NOT include any preamble or closing — just the numbered tips
      #{question ? "\n## User's Question\nThe user is also asking: #{question}\nAddress their question directly as your first tip, then continue with your other tips." : ""}
    PROMPT
  end

  private_class_method def self.call_api(api_key, prompt)
    uri = URI(API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 20

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["x-api-key"] = api_key
    request["anthropic-version"] = "2023-06-01"

    request.body = {
      model: MODEL,
      max_tokens: 600,
      messages: [ { role: "user", content: prompt } ]
    }.to_json

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn("DietAdvisor API error: #{response.code} #{response.body}")
      return nil
    end

    JSON.parse(response.body)
  end

  private_class_method def self.parse_response(response)
    return nil unless response
    text = response.dig("content", 0, "text")
    return nil unless text.present?
    text.strip
  end
end
