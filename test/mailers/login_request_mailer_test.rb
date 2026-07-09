require "test_helper"

class LoginRequestMailerTest < ActionMailer::TestCase
  setup do
    @org = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @manager = User.create!(organization: @org, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @pm_org = Organization.create!(name: "Acme PM", organization_type: "property_management")
    @request = LoginRequest.create!(
      email: "dan@acme.com", first_name: "Dan", last_name: "Hutson",
      organization: @pm_org, phone: "(210) 555-0100", message: "I manage the Sunset portfolio."
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
end
