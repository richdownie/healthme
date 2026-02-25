require "net/http"

class MedicationAnalyzer
  API_URL = "https://api.anthropic.com/v1/messages"
  MODEL = "claude-haiku-4-5-20251001"

  def self.analyze(name:, dose:, unit:, user:, medications_today: [])
    api_key = user.anthropic_api_key.presence || ENV["ANTHROPIC_API_KEY"]
    return nil unless api_key.present?
    return nil unless name.present?

    prompt = build_prompt(name, dose, unit, user, medications_today)
    response = call_api(api_key, prompt)
    parse_response(response)
  rescue StandardError => e
    Rails.logger.warn("MedicationAnalyzer error: #{e.message}")
    nil
  end

  private_class_method def self.build_prompt(name, dose, unit, user, medications_today)
    context = []
    context << "Medication/supplement: #{name}"
    context << "Dose: #{dose} #{unit}" if dose.present?
    context << "Age: #{user.age}" if user.respond_to?(:age) && user.age
    context << "Sex: #{user.sex}" if user.sex.present?
    context << "Weight: #{user.weight} lbs" if user.weight.present?
    context << "Activity level: #{user.activity_level&.humanize}" if user.activity_level.present?
    context << "Health concerns: #{user.health_concerns}" if user.health_concerns.present?

    if medications_today.any?
      med_list = medications_today.map { |a|
        desc = a.notes.present? ? "#{a.notes} (#{a.display_value})" : a.display_value
        desc
      }
      context << "Other medications/supplements taken today: #{med_list.join('; ')}"
    end

    prompt = "You are a health assistant. Analyze this medication or supplement in context of the user's profile.\n\n"
    prompt += context.join("\n")
    prompt += "\n\nProvide a brief analysis (3-5 sentences) covering:"
    prompt += "\n1. What this supplement/medication is commonly used for"
    prompt += "\n2. Whether the dose is within the typical recommended range"
    prompt += "\n3. Any interactions with other supplements taken today, if applicable"
    prompt += "\n4. One helpful tip (best time to take it, take with food, etc.)"
    prompt += "\n\nKeep it conversational and helpful. Do not give medical diagnoses."
    prompt += "\nAlso return a risk level: \"low\" if safe and typical, \"medium\" if dose is high or minor interaction concern, \"high\" if potentially dangerous interaction or very high dose."
    prompt += "\n\nRespond with ONLY a JSON object: {\"analysis\": \"your analysis text\", \"risk\": \"low|medium|high\", \"category\": \"Supplement|Medication|Vitamin|Mineral|Amino Acid|Herbal\"}"
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
      Rails.logger.warn("MedicationAnalyzer API error: #{response.code} #{response.body}")
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
      risk: data["risk"] || "low",
      category: data["category"]
    }
  rescue JSON::ParserError
    nil
  end
end
