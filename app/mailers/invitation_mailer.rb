class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @accept_url = invitation_url(invitation.token)
    mail(to: invitation.email, subject: "You've been invited to join #{invitation.organization.name}")
  end
end
