class LoginRequestMailer < ApplicationMailer
  def new_request(user, login_request)
    # Eligibility was checked at enqueue time, but the job may sit in the queue
    # (or retry for minutes); re-check at render time so a reviewer who was
    # deactivated or opted out in the meantime doesn't receive requester PII.
    return unless user.active? && user.can?(Permissions::MANAGE_USERS) &&
      user.notification_preference("login_request")

    @user = user
    @login_request = login_request
    mail(to: user.email_address, subject: "New login request from #{login_request.full_name}")
  end
end
