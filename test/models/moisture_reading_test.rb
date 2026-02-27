require "test_helper"

class MoistureReadingTest < ActiveSupport::TestCase
  setup do
    @org = Organization.create!(name: "TestOrg", organization_type: "mitigation")
    @pm_org = Organization.create!(name: "PMOrg", organization_type: "property_management")
    @property = Property.create!(name: "Test Property", mitigation_org: @org, property_management_org: @pm_org)
    @user = User.create!(organization: @org, user_type: "manager", email_address: "mgr@test.com",
      first_name: "Test", last_name: "User", password: "password123")
    @incident = Incident.create!(property: @property, created_by_user: @user,
      status: "active", project_type: "emergency_response", damage_type: "flood", description: "Test")
    @point = MoistureMeasurementPoint.create!(incident: @incident, unit: "1107", room: "Bathroom",
      item: "Wall", material: "Drywall", goal: "7.5", measurement_unit: "Pts")
  end

  test "valid reading" do
    reading = MoistureReading.new(moisture_measurement_point: @point,
      log_date: Date.current, value: 18.2, recorded_by_user: @user)
    assert reading.valid?
  end

  test "requires log_date" do
    reading = MoistureReading.new(moisture_measurement_point: @point, value: 18.2, recorded_by_user: @user)
    assert_not reading.valid?
    assert reading.errors[:log_date].any?
  end

  test "value can be nil" do
    reading = MoistureReading.new(moisture_measurement_point: @point,
      log_date: Date.current, value: nil, recorded_by_user: @user)
    assert reading.valid?
  end

  test "value must be non-negative" do
    reading = MoistureReading.new(moisture_measurement_point: @point,
      log_date: Date.current, value: -1, recorded_by_user: @user)
    assert_not reading.valid?
    assert reading.errors[:value].any?
  end

  test "uniqueness of point + date" do
    MoistureReading.create!(moisture_measurement_point: @point,
      log_date: Date.current, value: 18.2, recorded_by_user: @user)

    duplicate = MoistureReading.new(moisture_measurement_point: @point,
      log_date: Date.current, value: 15.0, recorded_by_user: @user)
    assert_not duplicate.valid?
    assert duplicate.errors[:moisture_measurement_point_id].any?
  end

  test "same point can have readings on different dates" do
    MoistureReading.create!(moisture_measurement_point: @point,
      log_date: Date.current, value: 18.2, recorded_by_user: @user)

    reading = MoistureReading.new(moisture_measurement_point: @point,
      log_date: Date.current + 1, value: 14.1, recorded_by_user: @user)
    assert reading.valid?
  end
end
