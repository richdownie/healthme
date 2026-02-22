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
  def self.estimate(images: [], notes: nil, category: nil, value: nil, unit: nil)
    api_key = ENV["ANTHROPIC_API_KEY"]
    return nil unless api_key.present?
    return nil if images.empty? && notes.blank?

    content = build_content(images, notes, category, value, unit)
    response = call_api(api_key, content)
    parse_response(response)
  rescue StandardError => e
    Rails.logger.warn("CalorieEstimator error: #{e.message}")
    nil
  end

  private_class_method def self.build_content(images, notes, category, value, unit)
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

    prompt = "Estimate the total calories for this food or activity."
    prompt += "\n#{context_parts.join("\n")}" if context_parts.any?
    prompt += "\n\nRespond with ONLY a JSON object like: {\"calories\": 350, \"description\": \"brief description of what you see\"}"
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
      max_tokens: 150,
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

    { calories: calories, description: description }
  rescue JSON::ParserError
    nil
  end
end
