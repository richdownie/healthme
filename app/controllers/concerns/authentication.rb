module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :signed_in?
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def signed_in?
    current_user.present?
  end

  def require_authentication
    unless signed_in?
      redirect_to new_session_path, alert: "Please sign in to continue."
    end
  end

  def set_current_user(user)
    session[:user_id] = user.id
  end

  def clear_current_user
    session.delete(:user_id)
    @current_user = nil
  end
end
