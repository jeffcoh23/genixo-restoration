require "test_helper"

class MoistureMeasurementPointTest < ActiveSupport::TestCase
  setup do
    @org = Organization.create!(name: "TestOrg", organization_type: "mitigation")
    @pm_org = Organization.create!(name: "PMOrg", organization_type: "property_management")
    @property = Property.create!(name: "Test Property", mitigation_org: @org, property_management_org: @pm_org)
    @user = User.create!(organization: @org, user_type: "manager", email_address: "mgr@test.com",
      first_name: "Test", last_name: "User", password: "password123")
    @incident = Incident.create!(property: @property, created_by_user: @user,
      status: "active", project_type: "emergency_response", damage_type: "flood", description: "Test")
  end

  test "valid point with all required fields" do
    point = MoistureMeasurementPoint.new(
      incident: @incident, unit: "1107", room: "Bathroom",
      item: "Wall", material: "Drywall", goal: "7.5", measurement_unit: "Pts"
    )
    assert point.valid?
  end

  test "requires unit" do
    point = MoistureMeasurementPoint.new(incident: @incident, room: "Bathroom",
      item: "Wall", material: "Drywall", goal: "7.5", measurement_unit: "Pts")
    assert_not point.valid?
    assert point.errors[:unit].any?
  end

  test "requires room" do
    point = MoistureMeasurementPoint.new(incident: @incident, unit: "1107",
      item: "Wall", material: "Drywall", goal: "7.5", measurement_unit: "Pts")
    assert_not point.valid?
    assert point.errors[:room].any?
  end

  test "requires item" do
    point = MoistureMeasurementPoint.new(incident: @incident, unit: "1107", room: "Bathroom",
      material: "Drywall", goal: "7.5", measurement_unit: "Pts")
    assert_not point.valid?
    assert point.errors[:item].any?
  end

  test "requires material" do
    point = MoistureMeasurementPoint.new(incident: @incident, unit: "1107", room: "Bathroom",
      item: "Wall", goal: "7.5", measurement_unit: "Pts")
    assert_not point.valid?
    assert point.errors[:material].any?
  end

  test "requires goal" do
    point = MoistureMeasurementPoint.new(incident: @incident, unit: "1107", room: "Bathroom",
      item: "Wall", material: "Drywall", measurement_unit: "Pts")
    assert_not point.valid?
    assert point.errors[:goal].any?
  end

  test "measurement_unit must be % or Pts" do
    point = MoistureMeasurementPoint.new(incident: @incident, unit: "1107", room: "Bathroom",
      item: "Wall", material: "Drywall", goal: "7.5", measurement_unit: "invalid")
    assert_not point.valid?
    assert point.errors[:measurement_unit].any?
  end

  test "measurement_unit accepts %" do
    point = MoistureMeasurementPoint.new(incident: @incident, unit: "1107", room: "Bathroom",
      item: "Wall", material: "Drywall", goal: "Dry", measurement_unit: "%")
    assert point.valid?
  end

  test "goal can be string like Dry" do
    point = MoistureMeasurementPoint.new(incident: @incident, unit: "1107", room: "Bathroom",
      item: "Wall", material: "Carpet", goal: "Dry", measurement_unit: "%")
    assert point.valid?
    assert_equal "Dry", point.goal
  end

  test "destroys associated readings on destroy" do
    point = MoistureMeasurementPoint.create!(incident: @incident, unit: "1107", room: "Bath",
      item: "Wall", material: "Drywall", goal: "7.5", measurement_unit: "Pts")
    point.moisture_readings.create!(log_date: Date.current, value: 18.2, recorded_by_user: @user)

    assert_difference "MoistureReading.count", -1 do
      point.destroy!
    end
  end
end
