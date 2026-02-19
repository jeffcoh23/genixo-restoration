class PasswordResetMailer < ApplicationMailer
  def reset_link(user)
    @user = user
    @token = user.generate_token_for(:password_reset)
    @reset_url = edit_password_reset_url(@token)

    mail(to: user.email_address, subject: "Reset your password")
  end
end
