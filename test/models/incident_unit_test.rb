require "test_helper"

class IncidentUnitTest < ActiveSupport::TestCase
  setup do
    @org = Organization.create!(name: "Test Org", organization_type: "mitigation")
    @pm_org = Organization.create!(name: "PM Org", organization_type: "property_management")
    @property = Property.create!(name: "Test Prop", mitigation_org: @org, property_management_org: @pm_org)
    @user = @org.users.create!(
      first_name: "Test", last_name: "User", email_address: "unit-test@example.com",
      user_type: "manager", password: "password123"
    )
    @incident = Incident.create!(
      property: @property, created_by_user: @user,
      status: "active", project_type: "emergency_response",
      damage_type: "flood", description: "Test"
    )
  end

  test "valid unit" do
    unit = @incident.incident_units.new(unit_number: "320", created_by_user: @user)
    assert unit.valid?
  end

  test "requires unit_number" do
    unit = @incident.incident_units.new(unit_number: "", created_by_user: @user)
    assert_not unit.valid?
    assert_includes unit.errors[:unit_number], "can't be blank"
  end

  test "belongs to incident" do
    unit = @incident.incident_units.create!(unit_number: "101", created_by_user: @user)
    assert_equal @incident, unit.incident
  end

  test "has many incident_tasks with dependent destroy" do
    unit = @incident.incident_units.create!(unit_number: "A", created_by_user: @user)
    unit.incident_tasks.create!(
      activity: "Remediation", start_date: Date.current, end_date: Date.current + 3,
      created_by_user: @user
    )
    assert_equal 1, unit.incident_tasks.count
    assert_difference "IncidentTask.count", -1 do
      unit.destroy!
    end
  end

  test "defaults needs_vacant to false" do
    unit = @incident.incident_units.create!(unit_number: "B", created_by_user: @user)
    assert_equal false, unit.needs_vacant
  end

  test "defaults position to 0" do
    unit = @incident.incident_units.create!(unit_number: "C", created_by_user: @user)
    assert_equal 0, unit.position
  end

  test "incident has_many incident_units with dependent destroy" do
    @incident.incident_units.create!(unit_number: "X", created_by_user: @user)
    @incident.incident_units.create!(unit_number: "Y", created_by_user: @user)
    assert_equal 2, @incident.incident_units.count
    assert_difference "IncidentUnit.count", -2 do
      @incident.destroy!
    end
  end
end
