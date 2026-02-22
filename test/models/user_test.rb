require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
  end

  test "profile_complete? returns true when required fields present" do
    assert @user.profile_complete?
  end

  test "profile_complete? returns false when weight missing" do
    @user.weight = nil
    assert_not @user.profile_complete?
  end

  test "age calculated from date of birth" do
    @user.date_of_birth = Date.new(1990, 5, 15)
    expected_age = Date.today.year - 1990
    expected_age -= 1 if Date.today < Date.new(Date.today.year, 5, 15)
    assert_equal expected_age, @user.age
  end

  test "age returns nil without date_of_birth" do
    @user.date_of_birth = nil
    assert_nil @user.age
  end

  test "validates weight is positive" do
    @user.weight = -5
    assert_not @user.valid?
    assert @user.errors[:weight].any?
  end

  test "validates sex inclusion" do
    @user.sex = "invalid"
    assert_not @user.valid?
    assert @user.errors[:sex].any?
  end

  test "allows nil profile fields" do
    @user.weight = nil
    @user.height = nil
    @user.sex = nil
    assert @user.valid?
  end

  test "blood pressure requires both or neither" do
    @user.blood_pressure_systolic = 120
    @user.blood_pressure_diastolic = nil
    assert_not @user.valid?
    assert @user.errors[:base].any?
  end

  test "recommendations returns hash when profile complete" do
    recs = @user.recommendations
    assert_not_nil recs
    assert recs[:daily_calories] > 0
    assert recs[:water_cups] > 0
  end

  test "recommendations returns nil when profile incomplete" do
    @user.weight = nil
    assert_nil @user.recommendations
  end
end
