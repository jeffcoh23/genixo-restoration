class PasswordResetsController < ApplicationController
  allow_unauthenticated_access

  def new
    render inertia: "Auth/ForgotPassword", props: {
      create_path: forgot_password_path,
      login_path: login_path
    }
  end

  def create
    user = User.find_by(email_address: params[:email_address])
    PasswordResetMailer.reset_link(user).deliver_now if user&.active?

    # Always show success to avoid leaking email existence
    redirect_to forgot_password_path, notice: "If that email is in our system, you'll receive a reset link shortly."
  end

  def edit
    user = User.find_by_token_for(:password_reset, params[:token])

    if user
      render inertia: "Auth/ResetPassword", props: {
        token: params[:token],
        update_path: password_reset_path(params[:token]),
        login_path: login_path
      }
    else
      redirect_to forgot_password_path, alert: "This reset link is invalid or has expired."
    end
  end

  def update
    user = User.find_by_token_for(:password_reset, params[:token])

    if user.nil?
      redirect_to forgot_password_path, alert: "This reset link is invalid or has expired."
      return
    end

    if params[:password].blank?
      redirect_to edit_password_reset_path(params[:token]), inertia: { errors: { password: "can't be blank" } }
      return
    end

    if params[:password] != params[:password_confirmation]
      redirect_to edit_password_reset_path(params[:token]), inertia: { errors: { password_confirmation: "doesn't match password" } }
      return
    end

    user.update!(password: params[:password])
    redirect_to login_path, notice: "Your password has been reset. Please sign in."
  end
end
