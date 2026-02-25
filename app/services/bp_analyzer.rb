require "net/http"

class BpAnalyzer
  API_URL = "https://api.anthropic.com/v1/messages"
  MODEL = "claude-haiku-4-5-20251001"

  def self.analyze(systolic:, diastolic:, user:, activities_today: [])
    api_key = user.anthropic_api_key.presence || ENV["ANTHROPIC_API_KEY"]
    return nil unless api_key.present?
    return nil unless systolic.present? && diastolic.present?

    prompt = build_prompt(systolic, diastolic, user, activities_today)
    response = call_api(api_key, prompt)
    parse_response(response)
  rescue StandardError => e
    Rails.logger.warn("BpAnalyzer error: #{e.message}")
    nil
  end

  private_class_method def self.build_prompt(systolic, diastolic, user, activities)
    time_now = Time.current.in_time_zone(user.timezone || "Eastern Time (US & Canada)")

    context = []
    context << "Blood pressure reading: #{systolic}/#{diastolic} mmHg"
    context << "Time of reading: #{time_now.strftime('%-I:%M %p')}"
    context << "Age: #{user.age}" if user.respond_to?(:age) && user.age
    context << "Sex: #{user.sex}" if user.sex.present?
    context << "Weight: #{user.weight} lbs" if user.weight.present?
    context << "Height: #{user.height} inches" if user.height.present?
    context << "Activity level: #{user.activity_level&.humanize}" if user.activity_level.present?
    context << "Health concerns: #{user.health_concerns}" if user.health_concerns.present?

    if user.blood_pressure_systolic.present? && user.blood_pressure_diastolic.present?
      context << "Baseline BP from profile: #{user.blood_pressure_systolic}/#{user.blood_pressure_diastolic}"
    end

    food_activities = activities.select { |a| a.category.in?(%w[food coffee]) }
    exercise_activities = activities.select { |a| a.category.in?(%w[walk run weights yoga]) }

    if food_activities.any?
      food_items = food_activities.map { |a|
        desc = a.notes.present? ? a.notes : a.display_value
        time = a.created_at.in_time_zone(user.timezone || "Eastern Time (US & Canada)").strftime("%-I:%M %p")
        "#{desc} at #{time}"
      }
      context << "Food/drink today: #{food_items.join('; ')}"
    end

    if exercise_activities.any?
      exercises = exercise_activities.map { |a|
        time = a.created_at.in_time_zone(user.timezone || "Eastern Time (US & Canada)").strftime("%-I:%M %p")
        "#{a.category.capitalize} #{a.display_value} at #{time}"
      }
      context << "Exercise today: #{exercises.join('; ')}"
    else
      context << "No exercise logged today"
    end

    prompt = "You are a health assistant. Analyze this blood pressure reading in context.\n\n"
    prompt += context.join("\n")
    prompt += "\n\nProvide a brief analysis (3-5 sentences) covering:"
    prompt += "\n1. Classification of the reading (normal, elevated, stage 1/2 hypertension)"
    prompt += "\n2. How time of day and today's food/caffeine may affect it"
    prompt += "\n3. Whether recent exercise could be a factor"
    prompt += "\n4. One actionable suggestion based on their profile"
    prompt += "\n\nKeep it conversational and helpful. Do not give medical diagnoses."
    prompt += "\nAlso return a risk level: \"low\", \"medium\", or \"high\"."
    prompt += "\n\nRespond with ONLY a JSON object: {\"analysis\": \"your analysis text\", \"risk\": \"low|medium|high\", \"classification\": \"Normal|Elevated|Stage 1|Stage 2\"}"
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
      Rails.logger.warn("BpAnalyzer API error: #{response.code} #{response.body}")
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
      risk: data["risk"] || "medium",
      classification: data["classification"]
    }
  rescue JSON::ParserError
    nil
  end
end
