ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all
  end
end

# Helper for integration tests to sign in
module SignInHelper
  def sign_in_as(user)
    # Set session via a test-specific approach
    post session_path, params: { test_user_id: user.id }
  rescue ActionController::RoutingError
    # ignored
  end
end

class ActionDispatch::IntegrationTest
  include SignInHelper
end
