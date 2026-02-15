require "test_helper"

class IncidentAssignmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")

    @property = Property.create!(
      name: "Sunset Apartments", property_management_org: @greystar,
      mitigation_org: @genixo, street_address: "100 Sunset Blvd",
      city: "Houston", state: "TX", zip: "77001"
    )

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "Test", last_name: "Tech", password: "password123")
    @office = User.create!(organization: @genixo, user_type: "office_sales",
      email_address: "office@genixo.com", first_name: "Test", last_name: "Office", password: "password123")

    @pm_user = User.create!(organization: @greystar, user_type: "property_manager",
      email_address: "pm@greystar.com", first_name: "Test", last_name: "PM", password: "password123")

    PropertyAssignment.create!(user: @pm_user, property: @property)

    @incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "flood", description: "Test incident", emergency: true
    )
    IncidentAssignment.create!(incident: @incident, user: @manager, assigned_by_user: @manager)
  end

  # --- Assign ---

  test "manager can assign a user" do
    login_as @manager
    assert_difference "IncidentAssignment.count", 1 do
      assert_difference "ActivityEvent.count", 1 do
        post incident_assignments_path(@incident), params: { user_id: @tech.id }
      end
    end
    assert_redirected_to incident_path(@incident)
    assert @incident.assigned_users.include?(@tech)
  end

  test "pm_user can assign their own org user" do
    login_as @pm_user
    other_pm = User.create!(organization: @greystar, user_type: "area_manager",
      email_address: "am@greystar.com", first_name: "Test", last_name: "AM", password: "password123")
    PropertyAssignment.create!(user: other_pm, property: @property)

    assert_difference "IncidentAssignment.count", 1 do
      post incident_assignments_path(@incident), params: { user_id: other_pm.id }
    end
    assert_redirected_to incident_path(@incident)
  end

  test "pm_user cannot assign mitigation user" do
    login_as @pm_user
    post incident_assignments_path(@incident), params: { user_id: @tech.id }
    assert_response :not_found
  end

  test "already assigned user is not in assignable scope" do
    login_as @manager
    # @manager is already assigned, so trying to assign again returns 404
    post incident_assignments_path(@incident), params: { user_id: @manager.id }
    assert_response :not_found
  end

  test "technician cannot assign users" do
    IncidentAssignment.create!(incident: @incident, user: @tech, assigned_by_user: @manager)
    login_as @tech
    post incident_assignments_path(@incident), params: { user_id: @office.id }
    assert_response :not_found
  end

  # --- Unassign ---

  test "manager can remove any assignment" do
    assignment = IncidentAssignment.create!(incident: @incident, user: @tech, assigned_by_user: @manager)
    login_as @manager
    assert_difference "IncidentAssignment.count", -1 do
      assert_difference "ActivityEvent.count", 1 do
        delete incident_assignment_path(@incident, assignment)
      end
    end
    assert_redirected_to incident_path(@incident)
  end

  test "pm_user can remove their own org user" do
    IncidentAssignment.create!(incident: @incident, user: @pm_user, assigned_by_user: @manager)
    other_pm = User.create!(organization: @greystar, user_type: "area_manager",
      email_address: "am2@greystar.com", first_name: "Test", last_name: "AM2", password: "password123")
    assignment = IncidentAssignment.create!(incident: @incident, user: other_pm, assigned_by_user: @manager)

    login_as @pm_user
    assert_difference "IncidentAssignment.count", -1 do
      delete incident_assignment_path(@incident, assignment)
    end
    assert_redirected_to incident_path(@incident)
  end

  test "pm_user cannot remove mitigation user" do
    assignment = IncidentAssignment.find_by(incident: @incident, user: @manager)
    IncidentAssignment.create!(incident: @incident, user: @pm_user, assigned_by_user: @manager)
    login_as @pm_user
    delete incident_assignment_path(@incident, assignment)
    assert_response :not_found
    assert IncidentAssignment.exists?(id: assignment.id)
  end

  test "assign logs activity event with user details" do
    login_as @manager
    post incident_assignments_path(@incident), params: { user_id: @tech.id }
    event = ActivityEvent.last
    assert_equal "user_assigned", event.event_type
    assert_equal @tech.id, event.metadata["assigned_user_id"]
  end

  private

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end
end
