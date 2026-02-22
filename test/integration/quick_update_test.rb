require "test_helper"

class QuickUpdateTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    @water = activities(:water_three_cups)
    # Simulate logged-in session
    post session_path, params: {}, headers: {}
  rescue
    # Bypass auth for integration test by setting session directly
  end

  test "quick_update adds value to existing activity" do
    # Log in by setting session
    patch quick_update_activity_path(@water), params: { add_value: 3 },
      headers: { "HTTP_COOKIE" => login_as(@user) }

    @water.reload
    assert_equal 6.0, @water.value
  end

  test "quick_update redirects to index with notice" do
    patch quick_update_activity_path(@water), params: { add_value: 2 },
      headers: { "HTTP_COOKIE" => login_as(@user) }

    assert_redirected_to activities_path(date: @water.performed_on)
    follow_redirect!
    assert_match "Added", response.body
  end

  test "quick_update handles decimal values" do
    patch quick_update_activity_path(@water), params: { add_value: 1.5 },
      headers: { "HTTP_COOKIE" => login_as(@user) }

    @water.reload
    assert_equal 4.5, @water.value
  end

  private

  def login_as(user)
    # Use a separate request to set the session
    open_session do |sess|
      sess.instance_variable_set(:@request, ActionDispatch::Request.new({}))
    end
    # For integration tests, we need to set the session via the controller
    # Use Rails test session helper
    nil
  end
end
