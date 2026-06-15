# Stable Play closed-testing opt-in link for our package; used as the default
# when ANDROID_OPT_IN_URL isn't overridden.
class InvitationMailer < ApplicationMailer
  DEFAULT_ANDROID_OPT_IN_URL = "https://play.google.com/apps/testing/com.genixo.restoration".freeze

  def invite(invitation)
    @invitation = invitation
    @accept_url = invitation_url(invitation.token)
    @guest = invitation.user_type == User::GUEST

    # Android closed-beta install links, read at send time so config changes
    # take effect without a code deploy. The Android block only renders when the
    # group URL is set, so the email stays clean until the beta is ready.
    @android_group_url = ENV["ANDROID_TESTER_GROUP_URL"].presence
    @android_opt_in_url = ENV["ANDROID_OPT_IN_URL"].presence || DEFAULT_ANDROID_OPT_IN_URL

    subject = if @guest
      "You've been invited to view incident details"
    else
      "You've been invited to join #{invitation.organization.name}"
    end

    mail(to: invitation.email, subject: subject)
  end
end
