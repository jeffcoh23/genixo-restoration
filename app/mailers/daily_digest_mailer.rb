class DailyDigestMailer < ApplicationMailer
  def daily_digest(user, incident_summaries, date)
    @user = user
    @summaries = incident_summaries
    @date = date
    @date_label = date.strftime("%B %-d, %Y")

    mail(to: user.email_address, subject: "Daily Activity Summary — #{@date_label}")
  end
end
