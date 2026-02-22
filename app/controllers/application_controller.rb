class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :require_authentication
  around_action :set_user_timezone

  private

  def set_user_timezone(&block)
    tz = current_user&.timezone.presence || "Eastern Time (US & Canada)"
    Time.use_zone(tz, &block)
  end
end
