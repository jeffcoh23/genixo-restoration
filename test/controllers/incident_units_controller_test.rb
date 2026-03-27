require "test_helper"

class IncidentUnitsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")

    @property = Property.create!(
      name: "Timeline Apartments", property_management_org: @greystar,
      mitigation_org: @genixo
    )

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr-timeline@genixo.com", first_name: "Test", last_name: "Manager",
      password: "password123", permissions: Permissions.defaults_for("manager"))
    @tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech-timeline@genixo.com", first_name: "Test", last_name: "Tech",
      password: "password123", permissions: Permissions.defaults_for("technician"))
    @office_sales = User.create!(organization: @genixo, user_type: "office_sales",
      email_address: "sales-timeline@genixo.com", first_name: "Test", last_name: "Sales",
      password: "password123", permissions: Permissions.defaults_for("office_sales"))
    @pm_user = User.create!(organization: @greystar, user_type: "property_manager",
      email_address: "pm-timeline@greystar.com", first_name: "Test", last_name: "PM",
      password: "password123", permissions: Permissions.defaults_for("property_manager"))

    PropertyAssignment.create!(user: @pm_user, property: @property)

    @incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "flood", description: "Timeline test incident", emergency: true
    )
    IncidentAssignment.create!(incident: @incident, user: @tech, assigned_by_user: @manager)
  end

  # --- Create ---

  test "manager can create unit" do
    login_as @manager
    assert_difference "IncidentUnit.count", 1 do
      post incident_incident_units_path(@incident), params: {
        incident_unit: { unit_number: "320", needs_vacant: true }
      }
    end
    assert_redirected_to timeline_incident_path(@incident)
    unit = IncidentUnit.last
    assert_equal "320", unit.unit_number
    assert_equal true, unit.needs_vacant
    assert_equal @manager.id, unit.created_by_user_id
  end

  test "technician can create unit (has manage_timeline permission)" do
    login_as @tech
    assert_difference "IncidentUnit.count", 1 do
      post incident_incident_units_path(@incident), params: {
        incident_unit: { unit_number: "Lobby" }
      }
    end
    assert_redirected_to timeline_incident_path(@incident)
  end

  test "office_sales cannot create unit (no manage_timeline permission)" do
    login_as @office_sales
    assert_no_difference "IncidentUnit.count" do
      post incident_incident_units_path(@incident), params: {
        incident_unit: { unit_number: "Lobby" }
      }
    end
    assert_response :not_found
  end

  test "PM user cannot create unit" do
    login_as @pm_user
    assert_no_difference "IncidentUnit.count" do
      post incident_incident_units_path(@incident), params: {
        incident_unit: { unit_number: "Lobby" }
      }
    end
    assert_response :not_found
  end

  test "create with blank unit_number returns error" do
    login_as @manager
    assert_no_difference "IncidentUnit.count" do
      post incident_incident_units_path(@incident), params: {
        incident_unit: { unit_number: "" }
      }
    end
    assert_redirected_to timeline_incident_path(@incident)
    assert_equal "Could not add unit.", flash[:alert]
  end

  test "create logs activity event" do
    login_as @manager
    assert_difference "ActivityEvent.count", 1 do
      post incident_incident_units_path(@incident), params: {
        incident_unit: { unit_number: "320" }
      }
    end
    event = ActivityEvent.last
    assert_equal "timeline_unit_created", event.event_type
    assert_equal "320", event.metadata["unit_number"]
  end

  # --- Update ---

  test "manager can update unit" do
    login_as @manager
    unit = create_unit("Old Name")
    patch incident_incident_unit_path(@incident, unit), params: {
      incident_unit: { unit_number: "New Name", needs_vacant: true }
    }
    assert_redirected_to timeline_incident_path(@incident)
    unit.reload
    assert_equal "New Name", unit.unit_number
    assert_equal true, unit.needs_vacant
  end

  test "technician can update unit" do
    login_as @tech
    unit = create_unit("Tech Unit")
    patch incident_incident_unit_path(@incident, unit), params: {
      incident_unit: { unit_number: "Updated" }
    }
    assert_redirected_to timeline_incident_path(@incident)
    assert_equal "Updated", unit.reload.unit_number
  end

  # --- Destroy ---

  test "manager can destroy unit" do
    login_as @manager
    unit = create_unit("To Delete")
    assert_difference "IncidentUnit.count", -1 do
      delete incident_incident_unit_path(@incident, unit)
    end
    assert_redirected_to timeline_incident_path(@incident)
  end

  test "destroy cascades to tasks" do
    login_as @manager
    unit = create_unit("Cascade")
    unit.incident_tasks.create!(
      activity: "Remediation", start_date: Date.current, end_date: Date.current + 3,
      created_by_user: @manager
    )
    assert_difference ["IncidentUnit.count", "IncidentTask.count"], -1 do
      delete incident_incident_unit_path(@incident, unit)
    end
  end

  test "destroy logs activity event" do
    login_as @manager
    unit = create_unit("Log Test")
    assert_difference "ActivityEvent.count", 1 do
      delete incident_incident_unit_path(@incident, unit)
    end
    event = ActivityEvent.last
    assert_equal "timeline_unit_deleted", event.event_type
    assert_equal "Log Test", event.metadata["unit_number"]
  end

  private

  def create_unit(name)
    @incident.incident_units.create!(unit_number: name, created_by_user: @manager)
  end

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end
end
