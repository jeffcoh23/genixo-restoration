require "test_helper"

class MailDeliveryJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @user = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
  end

  # Guards the config.action_mailer.delivery_job wiring: a typo in the class
  # name string (or a Zeitwerk rename) would silently fall back to the
  # retry-less ActionMailer default with no other CI signal.
  test "deliver_later enqueues through MailDeliveryJob" do
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test

    assert_enqueued_with(job: MailDeliveryJob) do
      PasswordResetMailer.reset_link(@user).deliver_later
    end
  ensure
    ActiveJob::Base.queue_adapter = original_adapter
  end

  # Guards the retry_on list: transient SMTP failures (Resend's 10 req/s rate
  # limit surfaces as Net::SMTPFatalError) must retry instead of permanently
  # dropping the email on first failure.
  test "registers retry handlers for transient SMTP failures" do
    handled = MailDeliveryJob.rescue_handlers.map(&:first)
    MailDeliveryJob::TRANSIENT_SMTP_ERRORS.each do |klass|
      assert_includes handled, klass.name
    end
  end
end
