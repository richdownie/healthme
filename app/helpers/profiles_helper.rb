module ProfilesHelper
  def format_height(total_inches)
    return nil unless total_inches
    feet = (total_inches / 12).to_i
    inches = (total_inches % 12).round(0)
    "#{feet}'#{inches}\""
  end
end
