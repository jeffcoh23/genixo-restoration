require "test_helper"

class PsychrometricReadingTest < ActiveSupport::TestCase
  setup do
    @org = Organization.create!(name: "TestOrg", organization_type: "mitigation")
    @pm_org = Organization.create!(name: "PMOrg", organization_type: "property_management")
    @property = Property.create!(name: "Test Property", mitigation_org: @org, property_management_org: @pm_org)
    @user = User.create!(organization: @org, user_type: "manager", email_address: "mgr@test.com",
      first_name: "Test", last_name: "User", password: "password123")
    @incident = Incident.create!(property: @property, created_by_user: @user,
      status: "active", project_type: "emergency_response", damage_type: "flood", description: "Test")
    @point = PsychrometricPoint.create!(incident: @incident, unit: "1107", room: "Bathroom")
  end

  test "valid reading with temperature and relative_humidity" do
    reading = PsychrometricReading.new(psychrometric_point: @point,
      log_date: Date.current, temperature: 78, relative_humidity: 65, recorded_by_user: @user)
    assert reading.valid?
  end

  test "requires log_date" do
    reading = PsychrometricReading.new(psychrometric_point: @point,
      temperature: 78, relative_humidity: 65, recorded_by_user: @user)
    assert_not reading.valid?
    assert reading.errors[:log_date].any?
  end

  test "temperature can be nil" do
    reading = PsychrometricReading.new(psychrometric_point: @point,
      log_date: Date.current, temperature: nil, relative_humidity: 65, recorded_by_user: @user)
    assert reading.valid?
  end

  test "relative_humidity can be nil" do
    reading = PsychrometricReading.new(psychrometric_point: @point,
      log_date: Date.current, temperature: 78, relative_humidity: nil, recorded_by_user: @user)
    assert reading.valid?
  end

  test "relative_humidity must be between 0 and 100" do
    reading = PsychrometricReading.new(psychrometric_point: @point,
      log_date: Date.current, temperature: 78, relative_humidity: 101, recorded_by_user: @user)
    assert_not reading.valid?
    assert reading.errors[:relative_humidity].any?

    reading.relative_humidity = -1
    assert_not reading.valid?
    assert reading.errors[:relative_humidity].any?
  end

  test "uniqueness of point + date" do
    PsychrometricReading.create!(psychrometric_point: @point,
      log_date: Date.current, temperature: 78, relative_humidity: 65, recorded_by_user: @user)

    duplicate = PsychrometricReading.new(psychrometric_point: @point,
      log_date: Date.current, temperature: 80, relative_humidity: 50, recorded_by_user: @user)
    assert_not duplicate.valid?
    assert duplicate.errors[:psychrometric_point_id].any?
  end

  test "same point can have readings on different dates" do
    PsychrometricReading.create!(psychrometric_point: @point,
      log_date: Date.current, temperature: 78, relative_humidity: 65, recorded_by_user: @user)

    reading = PsychrometricReading.new(psychrometric_point: @point,
      log_date: Date.current + 1, temperature: 76, relative_humidity: 55, recorded_by_user: @user)
    assert reading.valid?
  end

  # --- GPP auto-calculation ---

  test "calculates GPP on save when both temperature and relative_humidity present" do
    reading = PsychrometricReading.create!(psychrometric_point: @point,
      log_date: Date.current, temperature: 78, relative_humidity: 65, recorded_by_user: @user)

    assert_not_nil reading.gpp
    # Rh=65, F=78 → GPP ~93.2
    assert_in_delta 93.2, reading.gpp.to_f, 1.0
  end

  test "GPP is nil when temperature is missing" do
    reading = PsychrometricReading.create!(psychrometric_point: @point,
      log_date: Date.current, temperature: nil, relative_humidity: 65, recorded_by_user: @user)

    assert_nil reading.gpp
  end

  test "GPP is nil when relative_humidity is missing" do
    reading = PsychrometricReading.create!(psychrometric_point: @point,
      log_date: Date.current, temperature: 78, relative_humidity: nil, recorded_by_user: @user)

    assert_nil reading.gpp
  end

  test "GPP recalculates on update" do
    reading = PsychrometricReading.create!(psychrometric_point: @point,
      log_date: Date.current, temperature: 78, relative_humidity: 65, recorded_by_user: @user)
    original_gpp = reading.gpp

    reading.update!(relative_humidity: 45)
    assert_not_equal original_gpp, reading.gpp
    # Rh=45, F=78 → GPP ~64.1
    assert_in_delta 64.1, reading.gpp.to_f, 1.0
  end
end
