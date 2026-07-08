class LoginRequestMailer < ApplicationMailer
  def new_request(user, login_request)
    @user = user
    @login_request = login_request
    mail(to: user.email_address, subject: "New login request from #{login_request.full_name}")
  end
end
