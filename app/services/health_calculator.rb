class HealthCalculator
  ACTIVITY_MULTIPLIERS = {
    "sedentary"         => 1.2,
    "lightly_active"    => 1.375,
    "moderately_active" => 1.55,
    "very_active"       => 1.725,
    "extra_active"      => 1.9
  }.freeze

  GOAL_ADJUSTMENTS = {
    "lose_weight" => -500,
    "maintain"    => 0,
    "gain_muscle" => 300
  }.freeze

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def calculate
    return nil unless user.profile_complete?

    bmi_val = bmi
    bmr_val = bmr
    tdee_val = tdee(bmr_val)
    calorie_target = daily_calories(tdee_val)
    macros = macro_breakdown(calorie_target)
    water = water_intake

    activity_burn = (tdee_val - bmr_val).round(0)

    {
      bmi: bmi_val.round(1),
      bmi_category: bmi_category(bmi_val),
      bmr: bmr_val.round(0),
      tdee: tdee_val.round(0),
      daily_burn: tdee_val.round(0),
      resting_burn: bmr_val.round(0),
      activity_burn: activity_burn,
      daily_calories: calorie_target.round(0),
      water_oz: water.round(0),
      water_cups: (water / 8.0).round(1),
      protein_g: macros[:protein],
      carbs_g: macros[:carbs],
      fat_g: macros[:fat],
      goal_label: user.goal&.humanize || "Maintain"
    }
  end

  def bmi
    weight_kg = user.weight * 0.453592
    height_m = user.height * 0.0254
    weight_kg / (height_m**2)
  end

  # Mifflin-St Jeor equation
  def bmr
    weight_kg = user.weight * 0.453592
    height_cm = user.height * 2.54
    age = user.age

    base = (10 * weight_kg) + (6.25 * height_cm) - (5 * age)
    case user.sex
    when "male"   then base + 5
    when "female" then base - 161
    else base - 78
    end
  end

  def tdee(bmr_val = nil)
    bmr_val ||= bmr
    multiplier = ACTIVITY_MULTIPLIERS[user.activity_level] || 1.55
    bmr_val * multiplier
  end

  def daily_calories(tdee_val = nil)
    tdee_val ||= tdee
    adjustment = GOAL_ADJUSTMENTS[user.goal] || 0
    [tdee_val + adjustment, 1200].max
  end

  def water_intake
    base = user.weight * 0.5
    case user.activity_level
    when "very_active", "extra_active" then base * 1.2
    else base
    end
  end

  def macro_breakdown(calories)
    ratios = case user.goal
             when "lose_weight"  then { protein: 0.40, carbs: 0.30, fat: 0.30 }
             when "gain_muscle"  then { protein: 0.35, carbs: 0.40, fat: 0.25 }
             else                     { protein: 0.30, carbs: 0.40, fat: 0.30 }
             end

    {
      protein: (calories * ratios[:protein] / 4.0).round(0),
      carbs:   (calories * ratios[:carbs] / 4.0).round(0),
      fat:     (calories * ratios[:fat] / 9.0).round(0)
    }
  end

  private

  def bmi_category(bmi_val)
    case bmi_val
    when 0...18.5  then "Underweight"
    when 18.5...25 then "Normal"
    when 25...30   then "Overweight"
    else "Obese"
    end
  end
end
