require "net/http"

class SleepAnalyzer
  API_URL = "https://api.anthropic.com/v1/messages"
  MODEL = "claude-haiku-4-5-20251001"

  def self.analyze(hours:, notes:, user:, activities_today: [])
    api_key = user.anthropic_api_key.presence || ENV["ANTHROPIC_API_KEY"]
    return nil unless api_key.present?
    return nil unless hours.present?

    prompt = build_prompt(hours, notes, user, activities_today)
    response = call_api(api_key, prompt)
    parse_response(response)
  rescue StandardError => e
    Rails.logger.warn("SleepAnalyzer error: #{e.message}")
    nil
  end

  private_class_method def self.build_prompt(hours, notes, user, activities)
    context = []
    context << "Sleep duration: #{hours} hours"
    context << "Sleep notes: #{notes}" if notes.present?
    context << "Age: #{user.age}" if user.respond_to?(:age) && user.age
    context << "Sex: #{user.sex}" if user.sex.present?
    context << "Weight: #{user.weight} lbs" if user.weight.present?
    context << "Activity level: #{user.activity_level&.humanize}" if user.activity_level.present?
    context << "Health concerns: #{user.health_concerns}" if user.health_concerns.present?

    exercise = activities.select { |a| a.category.in?(%w[walk run weights yoga]) }
    if exercise.any?
      items = exercise.map { |a|
        time = a.created_at.in_time_zone(user.timezone || "Eastern Time (US & Canada)").strftime("%-I:%M %p")
        "#{a.category.capitalize} #{a.display_value} at #{time}"
      }
      context << "Exercise today: #{items.join('; ')}"
    end

    caffeine = activities.select { |a| a.category == "coffee" }
    if caffeine.any?
      items = caffeine.map { |a|
        time = a.created_at.in_time_zone(user.timezone || "Eastern Time (US & Canada)").strftime("%-I:%M %p")
        desc = a.notes.present? ? a.notes : a.display_value
        "#{desc} at #{time}"
      }
      context << "Caffeine today: #{items.join('; ')}"
    end

    food = activities.select { |a| a.category == "food" }
    if food.any?
      last_meal = food.max_by(&:created_at)
      time = last_meal.created_at.in_time_zone(user.timezone || "Eastern Time (US & Canada)").strftime("%-I:%M %p")
      context << "Last meal: #{last_meal.notes.presence || last_meal.display_value} at #{time}"
    end

    prompt = "You are a health assistant. Analyze this sleep entry in context of the user's day.\n\n"
    prompt += context.join("\n")
    prompt += "\n\nProvide a brief analysis (3-5 sentences) covering:"
    prompt += "\n1. Whether the sleep duration is adequate for their age/profile"
    prompt += "\n2. How today's exercise may affect sleep quality"
    prompt += "\n3. Whether caffeine timing could be a factor"
    prompt += "\n4. One actionable tip to improve sleep"
    prompt += "\n\nKeep it conversational and helpful. Do not give medical diagnoses."
    prompt += "\nAlso return a quality rating: \"good\" if duration and habits look solid, \"fair\" if minor concerns, \"poor\" if significant issues."
    prompt += "\n\nRespond with ONLY a JSON object: {\"analysis\": \"your analysis text\", \"quality\": \"good|fair|poor\", \"recommended_hours\": 8}"
    prompt += "\nDo not include any other text. Just the JSON."
    prompt
  end

  private_class_method def self.call_api(api_key, prompt)
    uri = URI(API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 15

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
      Rails.logger.warn("SleepAnalyzer API error: #{response.code} #{response.body}")
      return nil
    end

    JSON.parse(response.body)
  end

  private_class_method def self.parse_response(response)
    return nil unless response

    text = response.dig("content", 0, "text")
    return nil unless text.present?

    json_match = text.match(/\{.*\}/m)
    return nil unless json_match

    data = JSON.parse(json_match[0])
    return nil unless data["analysis"].present?

    {
      analysis: data["analysis"],
      quality: data["quality"] || "fair",
      recommended_hours: data["recommended_hours"]
    }
  rescue JSON::ParserError
    nil
  end
end
