require "test_helper"

class HealthCalculatorTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @calculator = HealthCalculator.new(@user)
  end

  test "calculates BMI correctly" do
    # 165 lbs = 74.84 kg, 70 in = 1.778 m
    # BMI = 74.84 / (1.778^2) = ~23.7
    bmi = @calculator.bmi
    assert_in_delta 23.7, bmi, 0.5
  end

  test "BMI category for normal weight" do
    result = @calculator.calculate
    assert_equal "Normal", result[:bmi_category]
  end

  test "calculates BMR for female" do
    bmr = @calculator.bmr
    assert_in_delta 1524, bmr, 50
  end

  test "calculates TDEE with moderately active multiplier" do
    tdee = @calculator.tdee
    assert_in_delta 2362, tdee, 100
  end

  test "daily calories equals TDEE for maintain goal" do
    tdee = @calculator.tdee
    daily = @calculator.daily_calories(tdee)
    assert_equal tdee.round(0), daily.round(0)
  end

  test "daily calories with lose_weight subtracts 500" do
    @user.goal = "lose_weight"
    calc = HealthCalculator.new(@user)
    tdee = calc.tdee
    daily = calc.daily_calories(tdee)
    assert_in_delta tdee - 500, daily, 1
  end

  test "daily calories never below 1200" do
    @user.weight = 90.0
    @user.activity_level = "sedentary"
    @user.goal = "lose_weight"
    calc = HealthCalculator.new(@user)
    assert calc.daily_calories >= 1200
  end

  test "calculate returns nil when profile incomplete" do
    @user.weight = nil
    calc = HealthCalculator.new(@user)
    assert_nil calc.calculate
  end

  test "macro breakdown sums to total calories" do
    result = @calculator.calculate
    total = (result[:protein_g] * 4) + (result[:carbs_g] * 4) + (result[:fat_g] * 9)
    assert_in_delta result[:daily_calories], total, 10
  end

  test "water intake based on weight" do
    water = @calculator.water_intake
    assert_in_delta 82.5, water, 1
  end

  test "water intake increases for very active" do
    @user.activity_level = "very_active"
    calc = HealthCalculator.new(@user)
    water = calc.water_intake
    assert_in_delta 99.0, water, 1
  end
end
