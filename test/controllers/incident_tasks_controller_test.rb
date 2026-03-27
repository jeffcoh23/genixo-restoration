require "test_helper"

class IncidentTasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")

    @property = Property.create!(
      name: "Task Test Apartments", property_management_org: @greystar,
      mitigation_org: @genixo
    )

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr-tasks@genixo.com", first_name: "Test", last_name: "Manager",
      password: "password123", permissions: Permissions.defaults_for("manager"))
    @tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech-tasks@genixo.com", first_name: "Test", last_name: "Tech",
      password: "password123", permissions: Permissions.defaults_for("technician"))
    @office_sales = User.create!(organization: @genixo, user_type: "office_sales",
      email_address: "sales-tasks@genixo.com", first_name: "Test", last_name: "Sales",
      password: "password123", permissions: Permissions.defaults_for("office_sales"))
    @pm_user = User.create!(organization: @greystar, user_type: "property_manager",
      email_address: "pm-tasks@greystar.com", first_name: "Test", last_name: "PM",
      password: "password123", permissions: Permissions.defaults_for("property_manager"))

    PropertyAssignment.create!(user: @pm_user, property: @property)

    @incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "flood", description: "Task test incident"
    )
    IncidentAssignment.create!(incident: @incident, user: @tech, assigned_by_user: @manager)

    @unit = @incident.incident_units.create!(unit_number: "320", created_by_user: @manager)
  end

  # --- Create ---

  test "manager can create task" do
    login_as @manager
    assert_difference "IncidentTask.count", 1 do
      post incident_incident_unit_incident_tasks_path(@incident, @unit), params: {
        incident_task: { activity: "Remediation", start_date: "2026-04-01", end_date: "2026-04-10" }
      }
    end
    assert_redirected_to timeline_incident_path(@incident)
    task = IncidentTask.last
    assert_equal "Remediation", task.activity
    assert_equal Date.parse("2026-04-01"), task.start_date
    assert_equal Date.parse("2026-04-10"), task.end_date
    assert_equal @manager.id, task.created_by_user_id
  end

  test "technician can create task" do
    login_as @tech
    assert_difference "IncidentTask.count", 1 do
      post incident_incident_unit_incident_tasks_path(@incident, @unit), params: {
        incident_task: { activity: "Rebuild", start_date: "2026-04-05", end_date: "2026-04-20" }
      }
    end
    assert_redirected_to timeline_incident_path(@incident)
  end

  test "office_sales cannot create task" do
    login_as @office_sales
    assert_no_difference "IncidentTask.count" do
      post incident_incident_unit_incident_tasks_path(@incident, @unit), params: {
        incident_task: { activity: "Rebuild", start_date: "2026-04-05", end_date: "2026-04-20" }
      }
    end
    assert_response :not_found
  end

  test "PM user cannot create task" do
    login_as @pm_user
    assert_no_difference "IncidentTask.count" do
      post incident_incident_unit_incident_tasks_path(@incident, @unit), params: {
        incident_task: { activity: "Rebuild", start_date: "2026-04-05", end_date: "2026-04-20" }
      }
    end
    assert_response :not_found
  end

  test "create with end_date before start_date returns error" do
    login_as @manager
    assert_no_difference "IncidentTask.count" do
      post incident_incident_unit_incident_tasks_path(@incident, @unit), params: {
        incident_task: { activity: "Bad Dates", start_date: "2026-04-10", end_date: "2026-04-01" }
      }
    end
    assert_redirected_to timeline_incident_path(@incident)
    assert_equal "Could not add task.", flash[:alert]
  end

  test "create logs activity event" do
    login_as @manager
    assert_difference "ActivityEvent.count", 1 do
      post incident_incident_unit_incident_tasks_path(@incident, @unit), params: {
        incident_task: { activity: "Painting", start_date: "2026-04-15", end_date: "2026-04-20" }
      }
    end
    event = ActivityEvent.last
    assert_equal "timeline_task_created", event.event_type
    assert_equal "320", event.metadata["unit_number"]
    assert_equal "Painting", event.metadata["activity"]
  end

  # --- Update ---

  test "manager can update task" do
    login_as @manager
    task = create_task("Remediation", "2026-04-01", "2026-04-10")
    patch incident_incident_unit_incident_task_path(@incident, @unit, task), params: {
      incident_task: { activity: "Deep Clean", start_date: "2026-04-02", end_date: "2026-04-12" }
    }
    assert_redirected_to timeline_incident_path(@incident)
    task.reload
    assert_equal "Deep Clean", task.activity
    assert_equal Date.parse("2026-04-02"), task.start_date
    assert_equal Date.parse("2026-04-12"), task.end_date
  end

  test "update with invalid dates returns error" do
    login_as @manager
    task = create_task("Fix Me", "2026-04-01", "2026-04-10")
    patch incident_incident_unit_incident_task_path(@incident, @unit, task), params: {
      incident_task: { end_date: "2026-03-01" }
    }
    assert_redirected_to timeline_incident_path(@incident)
    assert_equal "Could not update task.", flash[:alert]
    assert_equal Date.parse("2026-04-10"), task.reload.end_date
  end

  # --- Destroy ---

  test "manager can destroy task" do
    login_as @manager
    task = create_task("To Delete", "2026-04-01", "2026-04-05")
    assert_difference "IncidentTask.count", -1 do
      delete incident_incident_unit_incident_task_path(@incident, @unit, task)
    end
    assert_redirected_to timeline_incident_path(@incident)
  end

  test "destroy logs activity event" do
    login_as @manager
    task = create_task("Log Me", "2026-04-01", "2026-04-05")
    assert_difference "ActivityEvent.count", 1 do
      delete incident_incident_unit_incident_task_path(@incident, @unit, task)
    end
    event = ActivityEvent.last
    assert_equal "timeline_task_deleted", event.event_type
    assert_equal "Log Me", event.metadata["activity"]
  end

  # --- Scoping ---

  test "cannot create task on unit from different incident" do
    login_as @manager
    other_incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "new", project_type: "emergency_response",
      damage_type: "fire", description: "Other"
    )
    other_unit = other_incident.incident_units.create!(unit_number: "999", created_by_user: @manager)

    assert_no_difference "IncidentTask.count" do
      post incident_incident_unit_incident_tasks_path(@incident, other_unit), params: {
        incident_task: { activity: "Hack", start_date: "2026-04-01", end_date: "2026-04-05" }
      }
    end
    assert_response :not_found
  end

  private

  def create_task(activity, start_date, end_date)
    @unit.incident_tasks.create!(
      activity: activity, start_date: Date.parse(start_date), end_date: Date.parse(end_date),
      created_by_user: @manager
    )
  end

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end
end
