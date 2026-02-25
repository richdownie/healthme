require "net/http"

class CalorieEstimator
  API_URL = "https://api.anthropic.com/v1/messages"
  MODEL = "claude-haiku-4-5-20251001"

  # Estimate calories from photos and/or text description.
  #
  # @param images [Array<Hash>] Array of { data: "base64...", content_type: "image/jpeg" }
  # @param notes [String, nil] User's text description
  # @param category [String, nil] Activity category (meal, water, etc.)
  # @param value [String, nil] Amount (e.g. "0.5")
  # @param unit [String, nil] Unit (e.g. "cup")
  # @return [Hash, nil] { calories: Integer, description: String } or nil
  def self.estimate(images: [], notes: nil, category: nil, value: nil, unit: nil, health_concerns: nil, api_key: nil)
    api_key = api_key.presence || ENV["ANTHROPIC_API_KEY"]
    return nil unless api_key.present?
    return nil if images.empty? && notes.blank?

    content = build_content(images, notes, category, value, unit, health_concerns)
    response = call_api(api_key, content)
    parse_response(response)
  rescue StandardError => e
    Rails.logger.warn("CalorieEstimator error: #{e.message}")
    nil
  end

  private_class_method def self.build_content(images, notes, category, value, unit, health_concerns)
    parts = []

    images.each do |img|
      next unless img[:data].present? && img[:content_type].present?
      parts << {
        type: "image",
        source: {
          type: "base64",
          media_type: img[:content_type],
          data: img[:data]
        }
      }
    end

    context_parts = []
    context_parts << "Category: #{category}" if category.present?
    context_parts << "Amount: #{value} #{unit}".strip if value.present?
    context_parts << "Description: #{notes}" if notes.present?

    prompt = "Estimate the total calories and macronutrients for this food or activity."
    prompt += "\nWhen the unit is 'servings', treat 1 serving as 1 individual item (e.g. 1 egg, 1 apple, 1 slice). Do NOT use USDA reference servings. Estimate for exactly the specified amount." if value.present?
    if health_concerns.present?
      prompt += "\nThe user has these health concerns: #{health_concerns}."
      prompt += "\nRate the health risk of this food for someone with these conditions. Use: \"low\" (good/safe), \"medium\" (okay in moderation), or \"high\" (should avoid or limit)."
      prompt += "\nProvide a brief reason for the rating."
    end
    prompt += "\n#{context_parts.join("\n")}" if context_parts.any?
    prompt += "\n\nRespond with ONLY a JSON object like: {\"calories\": 350, \"protein_g\": 25.0, \"carbs_g\": 40.0, \"fat_g\": 12.0, \"fiber_g\": 5.0, \"sugar_g\": 8.0, \"description\": \"brief description\""
    prompt += ", \"health_risk\": \"low\", \"health_risk_reason\": \"brief reason\"" if health_concerns.present?
    prompt += "}"
    prompt += "\nAll nutrient values should be in grams. Estimate to one decimal place."
    prompt += "\nDo not include any other text. Just the JSON."

    parts << { type: "text", text: prompt }
    parts
  end

  private_class_method def self.call_api(api_key, content)
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
      max_tokens: 350,
      messages: [ { role: "user", content: content } ]
    }.to_json

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn("CalorieEstimator API error: #{response.code} #{response.body}")
      return nil
    end

    JSON.parse(response.body)
  end

  private_class_method def self.parse_response(response)
    return nil unless response

    text = response.dig("content", 0, "text")
    return nil unless text.present?

    json_match = text.match(/\{[^}]+\}/)
    return nil unless json_match

    data = JSON.parse(json_match[0])
    calories = data["calories"].to_i
    description = data["description"].to_s

    return nil if calories <= 0

    result = {
      calories: calories,
      description: description,
      protein_g: data["protein_g"]&.to_f&.round(1),
      carbs_g:   data["carbs_g"]&.to_f&.round(1),
      fat_g:     data["fat_g"]&.to_f&.round(1),
      fiber_g:   data["fiber_g"]&.to_f&.round(1),
      sugar_g:   data["sugar_g"]&.to_f&.round(1)
    }
    result[:health_risk] = data["health_risk"] if data["health_risk"].present?
    result[:health_risk_reason] = data["health_risk_reason"] if data["health_risk_reason"].present?
    result
  rescue JSON::ParserError
    nil
  end
end
