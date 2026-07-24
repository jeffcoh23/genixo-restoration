# Explicit require: this class references Net::SMTP error constants at class
# load time. Production eager-loads app/jobs before anything has touched the
# mail gem's SMTP path, so without this the constants may not exist yet and
# boot fails with NameError.
require "net/smtp"

# Wired in via config.action_mailer.delivery_job — every deliver_later goes
# through this class instead of ActionMailer::MailDeliveryJob, which has no
# retries: a single SMTP hiccup (Resend's 10 req/s rate limit, a timeout)
# silently drops the email forever.
#
# Net::SMTPFatalError also covers genuinely permanent 5xx failures (e.g.
# invalid recipient), which will burn all attempts before landing in failed
# executions — a few wasted retries is an acceptable price for not losing
# rate-limited mail. A retry after a timeout can double-deliver in the rare
# case the server accepted the message but the ack timed out; a duplicate
# email is a better failure mode than a silently lost one.
class MailDeliveryJob < ActionMailer::MailDeliveryJob
  TRANSIENT_SMTP_ERRORS = [
    Net::SMTPServerBusy, Net::SMTPFatalError,
    Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout,
    SocketError, EOFError, IOError,
    Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::ETIMEDOUT, Errno::EPIPE,
    OpenSSL::SSL::SSLError
  ].freeze

  retry_on(*TRANSIENT_SMTP_ERRORS, wait: :polynomially_longer, attempts: 5)
end
