require "test_helper"

class IncidentTest < ActiveSupport::TestCase
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @external = Organization.create!(name: "External", organization_type: "external")

    @property = Property.create!(
      name: "Sunset Apartments", property_management_org: @greystar,
      mitigation_org: @genixo, street_address: "100 Sunset Blvd",
      city: "Houston", state: "TX", zip: "77001"
    )

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")

    @incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "flood", description: "Test incident", emergency: true
    )
  end

  test "guest can see only assigned incidents" do
    guest = User.create!(organization: @external, user_type: "guest",
      email_address: "guest@example.com", first_name: "Jane", last_name: "Adjuster",
      title: "Insurance Adjuster", password: "password123")

    assert_equal 0, Incident.visible_to(guest).count

    IncidentAssignment.create!(incident: @incident, user: guest, assigned_by_user: @manager)

    assert_equal 1, Incident.visible_to(guest).count
    assert_includes Incident.visible_to(guest), @incident
  end

  # --- display_status ---

  test "display_status returns emergency for emergency new incident" do
    @incident.update!(status: "new", emergency: true)
    assert_equal "emergency", @incident.display_status
  end

  test "display_status returns emergency for emergency acknowledged incident" do
    @incident.update!(status: "acknowledged", emergency: true)
    assert_equal "emergency", @incident.display_status
  end

  test "display_status returns normal status for emergency active incident" do
    @incident.update!(status: "active", emergency: true)
    assert_equal "active", @incident.display_status
  end

  test "display_status returns normal status for non-emergency new incident" do
    @incident.update!(status: "new", emergency: false)
    assert_equal "new", @incident.display_status
  end

  # --- Guest visibility ---

  test "guest cannot see unassigned incidents" do
    guest = User.create!(organization: @external, user_type: "guest",
      email_address: "guest2@example.com", first_name: "Bob", last_name: "Owner",
      password: "password123")

    other_incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "fire", description: "Other incident"
    )

    IncidentAssignment.create!(incident: @incident, user: guest, assigned_by_user: @manager)

    assert_includes Incident.visible_to(guest), @incident
    assert_not_includes Incident.visible_to(guest), other_incident
  end
end
