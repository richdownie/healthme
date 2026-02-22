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
  def self.advise(user:, activities:, recommendations:)
    api_key = ENV["ANTHROPIC_API_KEY"]
    return nil unless api_key.present?
    return nil unless user.profile_complete?

    prompt = build_prompt(user, activities, recommendations)
    response = call_api(api_key, prompt)
    parse_response(response)
  rescue StandardError => e
    Rails.logger.warn("DietAdvisor error: #{e.message}")
    nil
  end

  private_class_method def self.build_prompt(user, activities, recs)
    food_log = activities.select { |a| a.category == "food" }.map do |a|
      parts = []
      parts << "#{a.value} #{a.unit}" if a.value.present?
      parts << a.notes if a.notes.present?
      parts << "(#{a.calories} cal)" if a.calories.present? && a.calories > 0
      parts.join(" — ")
    end

    water_cups = activities.select { |a| a.category == "water" }.sum(&:value)
    exercise = activities.select { |a| a.category.in?(Activity::BURN_CATEGORIES) }.map do |a|
      "#{a.category.humanize}: #{a.calories || 0} cal burned#{" — #{a.notes}" if a.notes.present?}"
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
      TARG
    else
      "No calculated targets available."
    end

    <<~PROMPT
      You are a helpful health and nutrition advisor. Based on this user's profile and today's food log, provide 3-4 brief, actionable diet tips.

      ## User Profile
      #{profile}
      ## Daily Targets
      #{targets}
      ## Today's Food Log
      #{food_log.any? ? food_log.join("\n") : "No food logged yet today."}

      Calories consumed so far: #{calories_in} cal
      Calories burned from exercise: #{calories_burned} cal
      Water consumed: #{water_cups.round(1)} cups

      ## Today's Exercise
      #{exercise.any? ? exercise.join("\n") : "No exercise logged."}

      ## Instructions
      - Give 3-4 short, specific, actionable tips based on what they've eaten today and their health profile
      - Consider their BMI, blood pressure, goal, and health concerns
      - Suggest specific foods they could add for the rest of the day
      - If they have high blood pressure, mention sodium awareness
      - Keep each tip to 1-2 sentences
      - Use a friendly, encouraging tone
      - Format as a simple numbered list (1. 2. 3.)
      - Do NOT include any preamble or closing — just the numbered tips
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
      max_tokens: 400,
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
