module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?, :current_user
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def authenticated?
    Current.session.present?
  end

  def current_user
    Current.user
  end

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    if (session_id = cookies.signed[:session_id])
      if (session = Session.find_by(id: session_id))
        if session.user.active?
          Current.session = session
          return true
        else
          # User was deactivated after login — terminate their session
          session.destroy
          cookies.delete(:session_id)
        end
      end
    end
    false
  end

  def request_authentication
    session[:return_to] = request.fullpath
    redirect_to login_path
  end

  def start_new_session_for(user)
    new_session = user.sessions.create!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
    Current.session = new_session
    cookies.signed.permanent[:session_id] = { value: new_session.id, httponly: true }
  end

  def terminate_session
    Current.session&.destroy
    cookies.delete(:session_id)
    Current.session = nil
  end
end
