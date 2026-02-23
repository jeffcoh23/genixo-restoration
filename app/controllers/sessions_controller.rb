class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    resume_session
    if authenticated?
      redirect_to incidents_path
      return
    end
    render inertia: "Login", props: {
      forgot_password_path: forgot_password_path
    }
  end

  def create
    user = User.find_by(email_address: params[:email_address])

    if user&.authenticate(params[:password])
      if user.active?
        start_new_session_for(user)
        redirect_to after_login_path, notice: "Welcome back, #{user.first_name}!"
      else
        redirect_to login_path, alert: "Your account has been deactivated. Contact your administrator."
      end
    else
      redirect_to login_path, alert: "Invalid email or password."
    end
  end

  def destroy
    terminate_session
    redirect_to login_path, notice: "You have been logged out."
  end

  private

  def after_login_path
    session.delete(:return_to) || incidents_path
  end
end
