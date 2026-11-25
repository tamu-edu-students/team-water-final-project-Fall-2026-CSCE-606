class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def require_login
    return if current_user

    session[:return_to] = request.fullpath if request.get?
    redirect_to login_path, alert: "Please log in first"
  end

  # Starts a fresh session and returns the page the visitor was sent away from, if any.
  def log_in(user)
    return_to = session[:return_to]
    reset_session
    session[:user_id] = user.id
    return_to || root_path
  end

  def require_logged_in_user
    render json: { error: "authentication required" }, status: :unauthorized unless current_user
  end
end
