require "test_helper"

class ActivitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    @water = activities(:water_three_cups)
    @meal = activities(:morning_meal)
  end

  test "duplicate route exists" do
    assert_routing(
      { method: :post, path: "/activities/#{@water.id}/duplicate" },
      { controller: "activities", action: "duplicate", id: @water.id.to_s }
    )
  end

  test "quick_update route exists" do
    assert_routing(
      { method: :patch, path: "/activities/#{@water.id}/quick_update" },
      { controller: "activities", action: "quick_update", id: @water.id.to_s }
    )
  end

  test "duplicate requires authentication" do
    post duplicate_activity_path(@water)
    assert_redirected_to new_session_path
  end

  test "quick_update requires authentication" do
    patch quick_update_activity_path(@water), params: { add_value: 3 }
    assert_redirected_to new_session_path
  end
end
