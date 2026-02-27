require "test_helper"

class MoistureReadingsControllerTest < ActionDispatch::IntegrationTest
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
      point: {
        unit: "1107", room: "Bathroom", item: "Wall",
        material: "Drywall", goal: "7.5", measurement_unit: "Pts"
      }
    }
  end

  # --- Create Point tests ---

  test "manager can create measurement point" do
    login_as @manager
    assert_difference "MoistureMeasurementPoint.count", 1 do
      post create_point_incident_moisture_readings_path(@incident), params: @point_params
    end
    assert_redirected_to incident_path(@incident)
    point = MoistureMeasurementPoint.last
    assert_equal "1107", point.unit
    assert_equal "Bathroom", point.room
    assert_equal "Drywall", point.material
    assert_equal "Pts", point.measurement_unit
  end

  test "manager can create point with first reading" do
    login_as @manager
    assert_difference [ "MoistureMeasurementPoint.count", "MoistureReading.count" ], 1 do
      post create_point_incident_moisture_readings_path(@incident), params: @point_params.merge(
        reading_value: "18.2", reading_date: Date.current.iso8601
      )
    end
    reading = MoistureReading.last
    assert_equal 18.2, reading.value.to_f
    assert_equal @manager.id, reading.recorded_by_user_id
  end

  test "technician can create measurement point" do
    login_as @tech
    assert_difference "MoistureMeasurementPoint.count", 1 do
      post create_point_incident_moisture_readings_path(@incident), params: @point_params
    end
    assert_redirected_to incident_path(@incident)
  end

  test "PM user cannot create measurement point" do
    login_as @pm_user
    assert_no_difference "MoistureMeasurementPoint.count" do
      post create_point_incident_moisture_readings_path(@incident), params: @point_params
    end
    assert_response :not_found
  end

  # --- Destroy Point tests ---

  test "manager can delete measurement point with cascading readings" do
    login_as @manager
    point = create_point!
    point.moisture_readings.create!(log_date: Date.current, value: 18.2, recorded_by_user: @manager)

    assert_difference "MoistureMeasurementPoint.count", -1 do
      assert_difference "MoistureReading.count", -1 do
        delete incident_moisture_point_path(@incident, point)
      end
    end
    assert_redirected_to incident_path(@incident)
  end

  test "technician can delete measurement point" do
    login_as @tech
    point = create_point!

    assert_difference "MoistureMeasurementPoint.count", -1 do
      delete incident_moisture_point_path(@incident, point)
    end
    assert_redirected_to incident_path(@incident)
  end

  # --- Batch Save tests ---

  test "manager can batch save readings for a date" do
    login_as @manager
    point1 = create_point!
    point2 = create_point!(room: "Bedroom", item: "Floor")

    assert_difference "MoistureReading.count", 2 do
      post batch_save_incident_moisture_readings_path(@incident), params: {
        log_date: Date.current.iso8601,
        readings: [
          { point_id: point1.id, value: "18.2" },
          { point_id: point2.id, value: "22.0" }
        ]
      }
    end
    assert_redirected_to incident_path(@incident)
  end

  test "batch save updates existing readings for same date" do
    login_as @manager
    point = create_point!
    point.moisture_readings.create!(log_date: Date.current, value: 18.2, recorded_by_user: @manager)

    assert_no_difference "MoistureReading.count" do
      post batch_save_incident_moisture_readings_path(@incident), params: {
        log_date: Date.current.iso8601,
        readings: [ { point_id: point.id, value: "14.1" } ]
      }
    end
    assert_equal 14.1, point.moisture_readings.find_by(log_date: Date.current).value.to_f
  end

  test "technician can batch save readings" do
    login_as @tech
    point = create_point!

    assert_difference "MoistureReading.count", 1 do
      post batch_save_incident_moisture_readings_path(@incident), params: {
        log_date: Date.current.iso8601,
        readings: [ { point_id: point.id, value: "18.2" } ]
      }
    end
    assert_redirected_to incident_path(@incident)
  end

  # --- Update Reading tests ---

  test "manager can update a single reading" do
    login_as @manager
    point = create_point!
    reading = point.moisture_readings.create!(log_date: Date.current, value: 18.2, recorded_by_user: @tech)

    patch incident_moisture_reading_path(@incident, reading), params: { value: "14.1" }
    assert_redirected_to incident_path(@incident)
    assert_equal 14.1, reading.reload.value.to_f
  end

  test "technician can edit reading created by different technician" do
    login_as @other_tech
    point = create_point!
    reading = point.moisture_readings.create!(log_date: Date.current, value: 18.2, recorded_by_user: @tech)

    patch incident_moisture_reading_path(@incident, reading), params: { value: "12.0" }
    assert_redirected_to incident_path(@incident)
    assert_equal 12.0, reading.reload.value.to_f
  end

  # --- Destroy Reading tests ---

  test "manager can delete a reading" do
    login_as @manager
    point = create_point!
    reading = point.moisture_readings.create!(log_date: Date.current, value: 18.2, recorded_by_user: @tech)

    assert_difference "MoistureReading.count", -1 do
      delete incident_moisture_reading_path(@incident, reading)
    end
    assert_redirected_to incident_path(@incident)
  end

  test "technician can delete a reading" do
    login_as @tech
    point = create_point!
    reading = point.moisture_readings.create!(log_date: Date.current, value: 18.2, recorded_by_user: @other_tech)

    assert_difference "MoistureReading.count", -1 do
      delete incident_moisture_reading_path(@incident, reading)
    end
    assert_redirected_to incident_path(@incident)
  end

  # --- Update Supervisor tests ---

  test "manager can update supervisor_pm" do
    login_as @manager
    patch update_supervisor_incident_moisture_readings_path(@incident), params: { moisture_supervisor_pm: "John Smith" }
    assert_redirected_to incident_path(@incident)
    assert_equal "John Smith", @incident.reload.moisture_supervisor_pm
  end

  test "technician can update supervisor_pm" do
    login_as @tech
    patch update_supervisor_incident_moisture_readings_path(@incident), params: { moisture_supervisor_pm: "Jane Doe" }
    assert_redirected_to incident_path(@incident)
    assert_equal "Jane Doe", @incident.reload.moisture_supervisor_pm
  end

  # --- PM User access tests ---

  test "PM user cannot batch save readings" do
    login_as @pm_user
    point = create_point!

    assert_no_difference "MoistureReading.count" do
      post batch_save_incident_moisture_readings_path(@incident), params: {
        log_date: Date.current.iso8601,
        readings: [ { point_id: point.id, value: "18.2" } ]
      }
    end
    assert_response :not_found
  end

  test "PM user cannot update supervisor" do
    login_as @pm_user
    patch update_supervisor_incident_moisture_readings_path(@incident), params: { moisture_supervisor_pm: "Nope" }
    assert_response :not_found
  end

  # --- Cross-incident isolation ---

  test "cannot access readings from another incident" do
    other_property = Property.create!(name: "Other Property", property_management_org: @greystar, mitigation_org: @genixo)
    other_incident = Incident.create!(property: other_property, created_by_user: @manager,
      status: "active", project_type: "emergency_response", damage_type: "flood", description: "Other")
    other_point = MoistureMeasurementPoint.create!(incident: other_incident, unit: "2001", room: "Kitchen",
      item: "Floor", material: "Tile", goal: "5", measurement_unit: "Pts")
    other_reading = other_point.moisture_readings.create!(log_date: Date.current, value: 10.0, recorded_by_user: @manager)

    login_as @manager
    # Try to update a reading from different incident
    patch incident_moisture_reading_path(@incident, other_reading), params: { value: "5.0" }
    assert_response :not_found
  end

  # --- ActivityLogger tests ---

  test "creating a point logs activity" do
    login_as @manager
    assert_difference "ActivityEvent.count" do
      post create_point_incident_moisture_readings_path(@incident), params: @point_params
    end
    event = ActivityEvent.last
    assert_equal "moisture_point_created", event.event_type
  end

  test "batch save logs activity" do
    login_as @manager
    point = create_point!

    assert_difference "ActivityEvent.count" do
      post batch_save_incident_moisture_readings_path(@incident), params: {
        log_date: Date.current.iso8601,
        readings: [ { point_id: point.id, value: "18.2" } ]
      }
    end
    event = ActivityEvent.last
    assert_equal "moisture_readings_recorded", event.event_type
  end

  private

  def create_point!(room: "Bathroom", item: "Wall")
    MoistureMeasurementPoint.create!(
      incident: @incident, unit: "1107", room: room,
      item: item, material: "Drywall", goal: "7.5", measurement_unit: "Pts"
    )
  end

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end
end
