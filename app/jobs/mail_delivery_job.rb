# Wired in via config.action_mailer.delivery_job — every deliver_later goes
# through this class instead of ActionMailer::MailDeliveryJob, which has no
# retries: a single SMTP hiccup (Resend's 10 req/s rate limit, a timeout)
# silently drops the email forever.
#
# Net::SMTPFatalError also covers genuinely permanent 5xx failures (e.g.
# invalid recipient), which will burn all attempts before landing in failed
# executions — a few wasted retries is an acceptable price for not losing
# rate-limited mail. Retrying a failed send can't double-deliver: the message
# never left the server.
class MailDeliveryJob < ActionMailer::MailDeliveryJob
  retry_on Net::SMTPServerBusy, Net::SMTPFatalError, Net::OpenTimeout, Net::ReadTimeout,
    wait: :polynomially_longer, attempts: 5
end
