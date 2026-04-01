require "application_system_test_case"

class TimelineTest < ApplicationSystemTestCase
  setup do
    @mitigation = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @pm = Organization.create!(name: "Greystar", organization_type: "property_management")

    @property = Property.create!(
      name: "River Oaks",
      property_management_org: @pm,
      mitigation_org: @mitigation
    )

    @manager = User.create!(
      organization: @mitigation,
      user_type: User::MANAGER,
      email_address: "timeline-mgr@example.com",
      first_name: "Mia",
      last_name: "Manager",
      password: "password123",
      permissions: Permissions.defaults_for("manager")
    )

    @pm_user = User.create!(
      organization: @pm,
      user_type: User::PROPERTY_MANAGER,
      email_address: "timeline-pm@example.com",
      first_name: "Pat",
      last_name: "PM",
      password: "password123",
      permissions: Permissions.defaults_for("property_manager")
    )

    PropertyAssignment.create!(user: @pm_user, property: @property)

    @incident = Incident.create!(
      property: @property,
      created_by_user: @manager,
      status: "active",
      project_type: "emergency_response",
      damage_type: "flood",
      description: "Timeline e2e test"
    )
  end

  test "manager can navigate to timeline from incident" do
    login_as @manager
    visit incident_path(@incident)

    click_link "Timeline"
    assert_text "Project Timeline"
    assert_text "No units yet"
  end

  test "manager can add a unit" do
    login_as @manager
    visit timeline_incident_path(@incident)

    click_button "Add First Unit"
    fill_in "Unit / Area Name", with: "Unit 320"
    check "Needs vacant"
    click_button "Add Unit"

    assert_text "Unit added."
    assert_text "Unit 320"
    assert_text "Yes" # needs_vacant badge
  end

  test "manager can add a task to a unit" do
    @incident.incident_units.create!(unit_number: "320", created_by_user: @manager)

    login_as @manager
    visit timeline_incident_path(@incident)

    assert_text "320"
    # Click the + button to add task
    find("button[title='Add task']").click

    fill_in "Activity", with: "Remediation"
    fill_in "Start Date", with: "2026-04-01"
    fill_in "End Date", with: "2026-04-10"
    click_button "Add Task"

    assert_text "Task added."
    assert_text "Remediation"
    assert_text "Apr 1, 2026"
    assert_text "Apr 10, 2026"
  end

  test "manager can edit a unit" do
    @incident.incident_units.create!(unit_number: "Old Name", created_by_user: @manager)

    login_as @manager
    visit timeline_incident_path(@incident)

    find("button[title='Edit unit']").click
    fill_in "Unit / Area Name", with: "New Name"
    click_button "Update"

    assert_text "Unit updated."
    assert_text "New Name"
  end

  test "manager can edit a task" do
    unit = @incident.incident_units.create!(unit_number: "320", created_by_user: @manager)
    unit.incident_tasks.create!(
      activity: "Remediation", start_date: Date.parse("2026-04-01"),
      end_date: Date.parse("2026-04-10"), created_by_user: @manager
    )

    login_as @manager
    visit timeline_incident_path(@incident)

    find("button[title='Edit task']").click
    fill_in "Activity", with: "Deep Clean"
    click_button "Update"

    assert_text "Task updated."
    assert_text "Deep Clean"
  end

  test "manager can delete a task" do
    unit = @incident.incident_units.create!(unit_number: "320", created_by_user: @manager)
    unit.incident_tasks.create!(
      activity: "To Delete", start_date: Date.parse("2026-04-01"),
      end_date: Date.parse("2026-04-05"), created_by_user: @manager
    )

    login_as @manager
    visit timeline_incident_path(@incident)

    assert_text "To Delete"
    accept_confirm do
      find("button[title='Delete task']").click
    end

    assert_text "Task removed."
    assert_no_text "To Delete"
  end

  test "manager can delete a unit" do
    @incident.incident_units.create!(unit_number: "Delete Me", created_by_user: @manager)

    login_as @manager
    visit timeline_incident_path(@incident)

    assert_text "Delete Me"
    accept_confirm do
      find("button[title='Delete unit']").click
    end

    assert_text "Unit removed."
    assert_no_text "Delete Me"
  end

  test "PM user sees timeline read-only (no add/edit/delete buttons)" do
    unit = @incident.incident_units.create!(unit_number: "320", created_by_user: @manager)
    unit.incident_tasks.create!(
      activity: "Remediation", start_date: Date.parse("2026-04-01"),
      end_date: Date.parse("2026-04-10"), created_by_user: @manager
    )

    login_as @pm_user
    visit timeline_incident_path(@incident)

    assert_text "Project Timeline"
    assert_text "320"
    assert_text "Remediation"

    # No management buttons
    assert_no_button "Add Unit"
    assert_no_css "button[title='Add task']"
    assert_no_css "button[title='Edit unit']"
    assert_no_css "button[title='Delete unit']"
    assert_no_css "button[title='Edit task']"
    assert_no_css "button[title='Delete task']"
  end

  test "gantt chart renders when tasks exist" do
    unit = @incident.incident_units.create!(unit_number: "320", created_by_user: @manager)
    unit.incident_tasks.create!(
      activity: "Remediation", start_date: Date.parse("2026-04-01"),
      end_date: Date.parse("2026-04-10"), created_by_user: @manager
    )
    unit.incident_tasks.create!(
      activity: "Rebuild", start_date: Date.parse("2026-04-11"),
      end_date: Date.parse("2026-04-25"), created_by_user: @manager
    )

    login_as @manager
    visit timeline_incident_path(@incident)

    # Gantt wrapper should be rendered
    assert_css ".gantt-wrapper"
    # Table should also be present
    assert_text "Remediation"
    assert_text "Rebuild"
  end

  test "back link returns to incident" do
    login_as @manager
    visit timeline_incident_path(@incident)

    click_link "Back to Incident"
    assert_current_path incident_path(@incident)
  end
end
