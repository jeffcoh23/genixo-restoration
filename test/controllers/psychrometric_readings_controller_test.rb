require "test_helper"

class PsychrometricReadingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")

    @property = Property.create!(
      name: "Sunset Apartments", property_management_org: @greystar,
      mitigation_org: @genixo
    )

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "Test", last_name: "Tech", password: "password123")
    @other_tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech2@genixo.com", first_name: "Other", last_name: "Tech", password: "password123")
    @pm_user = User.create!(organization: @greystar, user_type: "property_manager",
      email_address: "pm@greystar.com", first_name: "Test", last_name: "PM", password: "password123")

    PropertyAssignment.create!(user: @pm_user, property: @property)

    @incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "flood", description: "Test incident", emergency: true
    )
    IncidentAssignment.create!(incident: @incident, user: @tech, assigned_by_user: @manager)
    IncidentAssignment.create!(incident: @incident, user: @other_tech, assigned_by_user: @manager)

    @point_params = {
      point: { unit: "1107", room: "Bathroom", dehumidifier_label: "Dehu 1" }
    }
  end

  # --- Create Point tests ---

  test "manager can create psychrometric point" do
    login_as @manager
    assert_difference "PsychrometricPoint.count", 1 do
      post create_point_incident_psychrometric_readings_path(@incident), params: @point_params
    end
    assert_redirected_to incident_path(@incident)
    point = PsychrometricPoint.last
    assert_equal "1107", point.unit
    assert_equal "Bathroom", point.room
    assert_equal "Dehu 1", point.dehumidifier_label
  end

  test "manager can create point with first reading" do
    login_as @manager
    assert_difference [ "PsychrometricPoint.count", "PsychrometricReading.count" ], 1 do
      post create_point_incident_psychrometric_readings_path(@incident), params: @point_params.merge(
        reading_temperature: "78", reading_relative_humidity: "65", reading_date: Date.current.iso8601
      )
    end
    reading = PsychrometricReading.last
    assert_equal 78.0, reading.temperature.to_f
    assert_equal 65.0, reading.relative_humidity.to_f
    assert_not_nil reading.gpp
    assert_equal @manager.id, reading.recorded_by_user_id
  end

  test "technician can create psychrometric point" do
    login_as @tech
    assert_difference "PsychrometricPoint.count", 1 do
      post create_point_incident_psychrometric_readings_path(@incident), params: @point_params
    end
    assert_redirected_to incident_path(@incident)
  end

  test "PM user cannot create psychrometric point" do
    login_as @pm_user
    assert_no_difference "PsychrometricPoint.count" do
      post create_point_incident_psychrometric_readings_path(@incident), params: @point_params
    end
    assert_response :not_found
  end

  # --- Destroy Point tests ---

  test "manager can delete psychrometric point with cascading readings" do
    login_as @manager
    point = create_point!
    point.psychrometric_readings.create!(log_date: Date.current, temperature: 78, relative_humidity: 65, recorded_by_user: @manager)

    assert_difference "PsychrometricPoint.count", -1 do
      assert_difference "PsychrometricReading.count", -1 do
        delete incident_psychrometric_point_path(@incident, point)
      end
    end
    assert_redirected_to incident_path(@incident)
  end

  test "technician can delete psychrometric point" do
    login_as @tech
    point = create_point!

    assert_difference "PsychrometricPoint.count", -1 do
      delete incident_psychrometric_point_path(@incident, point)
    end
    assert_redirected_to incident_path(@incident)
  end

  # --- Batch Save tests ---

  test "manager can batch save readings for a date" do
    login_as @manager
    point1 = create_point!
    point2 = create_point!(room: "Bedroom")

    assert_difference "PsychrometricReading.count", 2 do
      post batch_save_incident_psychrometric_readings_path(@incident), params: {
        log_date: Date.current.iso8601,
        readings: [
          { point_id: point1.id, temperature: "78", relative_humidity: "65" },
          { point_id: point2.id, temperature: "72", relative_humidity: "45" }
        ]
      }
    end
    assert_redirected_to incident_path(@incident)

    r1 = point1.psychrometric_readings.find_by(log_date: Date.current)
    assert_not_nil r1.gpp
  end

  test "batch save updates existing readings for same date" do
    login_as @manager
    point = create_point!
    point.psychrometric_readings.create!(log_date: Date.current, temperature: 78, relative_humidity: 65, recorded_by_user: @manager)

    assert_no_difference "PsychrometricReading.count" do
      post batch_save_incident_psychrometric_readings_path(@incident), params: {
        log_date: Date.current.iso8601,
        readings: [ { point_id: point.id, temperature: "80", relative_humidity: "50" } ]
      }
    end
    reading = point.psychrometric_readings.find_by(log_date: Date.current)
    assert_equal 80.0, reading.temperature.to_f
    assert_equal 50.0, reading.relative_humidity.to_f
  end

  test "technician can batch save readings" do
    login_as @tech
    point = create_point!

    assert_difference "PsychrometricReading.count", 1 do
      post batch_save_incident_psychrometric_readings_path(@incident), params: {
        log_date: Date.current.iso8601,
        readings: [ { point_id: point.id, temperature: "78", relative_humidity: "65" } ]
      }
    end
    assert_redirected_to incident_path(@incident)
  end

  # --- Update Reading tests ---

  test "manager can update a single reading" do
    login_as @manager
    point = create_point!
    reading = point.psychrometric_readings.create!(log_date: Date.current, temperature: 78, relative_humidity: 65, recorded_by_user: @tech)

    patch incident_psychrometric_reading_path(@incident, reading), params: { temperature: "80", relative_humidity: "50" }
    assert_redirected_to incident_path(@incident)
    reading.reload
    assert_equal 80.0, reading.temperature.to_f
    assert_equal 50.0, reading.relative_humidity.to_f
  end

  test "technician can edit reading created by different technician" do
    login_as @other_tech
    point = create_point!
    reading = point.psychrometric_readings.create!(log_date: Date.current, temperature: 78, relative_humidity: 65, recorded_by_user: @tech)

    patch incident_psychrometric_reading_path(@incident, reading), params: { temperature: "76", relative_humidity: "55" }
    assert_redirected_to incident_path(@incident)
    reading.reload
    assert_equal 76.0, reading.temperature.to_f
    assert_equal 55.0, reading.relative_humidity.to_f
  end

  # --- Destroy Reading tests ---

  test "manager can delete a reading" do
    login_as @manager
    point = create_point!
    reading = point.psychrometric_readings.create!(log_date: Date.current, temperature: 78, relative_humidity: 65, recorded_by_user: @tech)

    assert_difference "PsychrometricReading.count", -1 do
      delete incident_psychrometric_reading_path(@incident, reading)
    end
    assert_redirected_to incident_path(@incident)
  end

  test "technician can delete a reading" do
    login_as @tech
    point = create_point!
    reading = point.psychrometric_readings.create!(log_date: Date.current, temperature: 78, relative_humidity: 65, recorded_by_user: @other_tech)

    assert_difference "PsychrometricReading.count", -1 do
      delete incident_psychrometric_reading_path(@incident, reading)
    end
    assert_redirected_to incident_path(@incident)
  end

  # --- PM User access tests ---

  test "PM user cannot batch save readings" do
    login_as @pm_user
    point = create_point!

    assert_no_difference "PsychrometricReading.count" do
      post batch_save_incident_psychrometric_readings_path(@incident), params: {
        log_date: Date.current.iso8601,
        readings: [ { point_id: point.id, temperature: "78", relative_humidity: "65" } ]
      }
    end
    assert_response :not_found
  end

  # --- Cross-incident isolation ---

  test "cannot access readings from another incident" do
    other_property = Property.create!(name: "Other Property", property_management_org: @greystar, mitigation_org: @genixo)
    other_incident = Incident.create!(property: other_property, created_by_user: @manager,
      status: "active", project_type: "emergency_response", damage_type: "flood", description: "Other")
    other_point = PsychrometricPoint.create!(incident: other_incident, unit: "2001", room: "Kitchen")
    other_reading = other_point.psychrometric_readings.create!(log_date: Date.current, temperature: 72, relative_humidity: 50, recorded_by_user: @manager)

    login_as @manager
    patch incident_psychrometric_reading_path(@incident, other_reading), params: { temperature: "80" }
    assert_response :not_found
  end

  # --- ActivityLogger tests ---

  test "creating a point logs activity" do
    login_as @manager
    assert_difference "ActivityEvent.count" do
      post create_point_incident_psychrometric_readings_path(@incident), params: @point_params
    end
    event = ActivityEvent.last
    assert_equal "psychrometric_point_created", event.event_type
  end

  test "batch save logs activity" do
    login_as @manager
    point = create_point!

    assert_difference "ActivityEvent.count" do
      post batch_save_incident_psychrometric_readings_path(@incident), params: {
        log_date: Date.current.iso8601,
        readings: [ { point_id: point.id, temperature: "78", relative_humidity: "65" } ]
      }
    end
    event = ActivityEvent.last
    assert_equal "psychrometric_readings_recorded", event.event_type
  end

  private

  def create_point!(room: "Bathroom")
    PsychrometricPoint.create!(
      incident: @incident, unit: "1107", room: room, dehumidifier_label: "Dehu 1"
    )
  end

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end
end
