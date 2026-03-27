require "test_helper"

class TimelineControllerTest < ActionDispatch::IntegrationTest
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")

    @property = Property.create!(
      name: "Timeline Prop", property_management_org: @greystar,
      mitigation_org: @genixo
    )

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr-tl@genixo.com", first_name: "Test", last_name: "Manager",
      password: "password123", permissions: Permissions.defaults_for("manager"))
    @pm_user = User.create!(organization: @greystar, user_type: "property_manager",
      email_address: "pm-tl@greystar.com", first_name: "Test", last_name: "PM",
      password: "password123", permissions: Permissions.defaults_for("property_manager"))

    PropertyAssignment.create!(user: @pm_user, property: @property)

    @incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "flood", description: "Timeline test"
    )
  end

  test "manager can view timeline page" do
    login_as @manager
    get timeline_incident_path(@incident)
    assert_response :success
  end

  test "PM user can view timeline page (read-only)" do
    login_as @pm_user
    get timeline_incident_path(@incident)
    assert_response :success
  end

  test "timeline includes units and tasks data" do
    login_as @manager
    unit = @incident.incident_units.create!(unit_number: "320", created_by_user: @manager)
    unit.incident_tasks.create!(
      activity: "Remediation", start_date: Date.parse("2026-04-01"),
      end_date: Date.parse("2026-04-10"), created_by_user: @manager
    )

    get timeline_incident_path(@incident)
    assert_response :success
  end

  test "unauthenticated user cannot access timeline" do
    get timeline_incident_path(@incident)
    assert_redirected_to login_path
  end

  private

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end
end
