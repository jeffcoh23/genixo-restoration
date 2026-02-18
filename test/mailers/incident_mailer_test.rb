require "test_helper"

class IncidentMailerTest < ActiveSupport::TestCase
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @property = Property.create!(name: "Sunset Apts", street_address: "123 Main St", city: "Austin", state: "TX", mitigation_org: @genixo, property_management_org: @greystar)

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")

    @incident = Incident.create!(
      property: @property, created_by_user: @manager, status: "acknowledged",
      project_type: "emergency_response", damage_type: "flood", description: "Water damage", emergency: true
    )
  end

  test "creation_confirmation sends to creator" do
    email = IncidentMailer.creation_confirmation(@incident)
    assert_equal [ "mgr@genixo.com" ], email.to
    assert_includes email.subject, "Sunset Apts"
  end

  test "status_changed sends to specified user" do
    email = IncidentMailer.status_changed(@manager, @incident, "acknowledged", "active")
    assert_equal [ "mgr@genixo.com" ], email.to
    assert_includes email.subject, "Active"
  end

  test "user_assigned sends to assigned user" do
    tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "Tech", last_name: "User", password: "password123")

    email = IncidentMailer.user_assigned(@incident, tech)
    assert_equal [ "tech@genixo.com" ], email.to
    assert_includes email.subject, "assigned"
  end

  test "new_message sends to specified user" do
    message = @incident.messages.create!(user: @manager, body: "Test message body")

    other = User.create!(organization: @genixo, user_type: "office_sales",
      email_address: "other@genixo.com", first_name: "Other", last_name: "User", password: "password123")

    email = IncidentMailer.new_message(other, message)
    assert_equal [ "other@genixo.com" ], email.to
    assert_includes email.subject, "message"
  end

  test "escalation_alert sends emergency email" do
    email = IncidentMailer.escalation_alert(@incident, @manager)
    assert_equal [ "mgr@genixo.com" ], email.to
    assert_includes email.subject, "EMERGENCY"
  end
end
