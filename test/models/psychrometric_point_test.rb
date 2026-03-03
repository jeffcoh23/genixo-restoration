require "test_helper"

class PsychrometricPointTest < ActiveSupport::TestCase
  setup do
    @org = Organization.create!(name: "TestOrg", organization_type: "mitigation")
    @pm_org = Organization.create!(name: "PMOrg", organization_type: "property_management")
    @property = Property.create!(name: "Test Property", mitigation_org: @org, property_management_org: @pm_org)
    @user = User.create!(organization: @org, user_type: "manager", email_address: "mgr@test.com",
      first_name: "Test", last_name: "User", password: "password123")
    @incident = Incident.create!(property: @property, created_by_user: @user,
      status: "active", project_type: "emergency_response", damage_type: "flood", description: "Test")
  end

  test "valid point with required fields" do
    point = PsychrometricPoint.new(incident: @incident, unit: "1107", room: "Bathroom")
    assert point.valid?
  end

  test "requires unit" do
    point = PsychrometricPoint.new(incident: @incident, room: "Bathroom")
    assert_not point.valid?
    assert point.errors[:unit].any?
  end

  test "requires room" do
    point = PsychrometricPoint.new(incident: @incident, unit: "1107")
    assert_not point.valid?
    assert point.errors[:room].any?
  end

  test "dehumidifier_label is optional" do
    point = PsychrometricPoint.new(incident: @incident, unit: "1107", room: "Bathroom", dehumidifier_label: nil)
    assert point.valid?
  end

  test "dehumidifier_label can be set" do
    point = PsychrometricPoint.create!(incident: @incident, unit: "1107", room: "Bathroom", dehumidifier_label: "Dehu 1")
    assert_equal "Dehu 1", point.dehumidifier_label
  end

  test "destroys associated readings on destroy" do
    point = PsychrometricPoint.create!(incident: @incident, unit: "1107", room: "Bathroom")
    point.psychrometric_readings.create!(log_date: Date.current, temperature: 78, relative_humidity: 65, recorded_by_user: @user)

    assert_difference "PsychrometricReading.count", -1 do
      point.destroy!
    end
  end
end
