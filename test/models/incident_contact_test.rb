require "test_helper"

class IncidentContactTest < ActiveSupport::TestCase
  setup do
    @org = Organization.create!(name: "Test Org", organization_type: "mitigation")
    @pm_org = Organization.create!(name: "PM Org", organization_type: "property_management")
    @property = Property.create!(name: "Test Property", mitigation_org: @org, property_management_org: @pm_org)
    @user = User.create!(organization: @org, user_type: "manager",
      email_address: "test@example.com", first_name: "Test", last_name: "User", password: "password123")
    @incident = Incident.create!(property: @property, created_by_user: @user,
      status: "active", project_type: "emergency_response", damage_type: "flood", description: "Test")
  end

  test "normalizes phone to digits only" do
    contact = @incident.incident_contacts.create!(
      name: "John", phone: "(555) 123-4567", created_by_user: @user
    )
    assert_equal "5551234567", contact.phone
  end

  test "normalizes phone strips leading 1" do
    contact = @incident.incident_contacts.create!(
      name: "Jane", phone: "1-555-123-4567", created_by_user: @user
    )
    assert_equal "5551234567", contact.phone
  end

  test "normalizes blank phone to nil" do
    contact = @incident.incident_contacts.create!(
      name: "Bob", phone: "", created_by_user: @user
    )
    assert_nil contact.phone
  end
end
