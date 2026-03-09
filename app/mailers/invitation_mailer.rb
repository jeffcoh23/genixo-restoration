class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @accept_url = invitation_url(invitation.token)
    @guest = invitation.user_type == User::GUEST

    subject = if @guest
      "You've been invited to view incident details"
    else
      "You've been invited to join #{invitation.organization.name}"
    end

    mail(to: invitation.email, subject: subject)
  end
end
