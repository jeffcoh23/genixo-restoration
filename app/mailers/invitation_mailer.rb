class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @accept_url = invitation_url(invitation.token)
    @guest = invitation.user_type == User::GUEST

    # Mobile install links (see MobileAppLinks). iOS is live on the App Store
    # (always shown); the Android beta steps only render when the tester group
    # URL is configured, so they vanish once Android goes public.
    @ios_app_store_url = MobileAppLinks.ios_app_store_url
    @android_group_url = MobileAppLinks.android_tester_group_url
    @android_opt_in_url = MobileAppLinks.android_opt_in_url

    subject = if @guest
      "You've been invited to view incident details"
    else
      "You've been invited to join #{invitation.organization.name}"
    end

    mail(to: invitation.email, subject: subject)
  end
end
