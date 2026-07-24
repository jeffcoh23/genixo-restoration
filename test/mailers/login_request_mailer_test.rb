require "test_helper"

class LoginRequestMailerTest < ActionMailer::TestCase
  setup do
    @org = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @manager = User.create!(organization: @org, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123",
      notification_preferences: { "login_request" => true })
    @request = LoginRequest.create!(
      email: "dan@acme.com", first_name: "Dan", last_name: "Hutson",
      company_name: "Acme PM", phone: "(210) 555-0100", message: "I manage the Sunset portfolio."
    )
  end

  test "notifies the reviewer with the requester's details" do
    mail = LoginRequestMailer.new_request(@manager, @request)

    assert_equal [ "mgr@genixo.com" ], mail.to
    assert_includes mail.subject, "Dan Hutson"
    [ mail.html_part.body.to_s, mail.text_part.body.to_s ].each do |body|
      assert_includes body, "dan@acme.com"
      assert_includes body, "Acme PM"
      assert_includes body, "I manage the Sunset portfolio."
    end
  end

  test "omits blank optional fields" do
    @request.update!(company_name: nil, message: nil)
    mail = LoginRequestMailer.new_request(@manager, @request)
    refute_includes mail.html_part.body.to_s, "Company"
  end

  # Eligibility can change between enqueue and render (deactivation, opt-out);
  # the mailer must re-check so queued jobs don't leak requester PII.
  test "sends nothing when the reviewer was deactivated after enqueue" do
    @manager.update!(active: false)
    assert_emails 0 do
      LoginRequestMailer.new_request(@manager, @request).deliver_now
    end
  end

  test "sends nothing when the reviewer opted out after enqueue" do
    @manager.update!(notification_preferences: { "login_request" => false })
    assert_emails 0 do
      LoginRequestMailer.new_request(@manager, @request).deliver_now
    end
  end
end
