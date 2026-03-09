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

  # --- Notification overrides ---

  test "user can update their own notification overrides" do
    assignment = IncidentAssignment.find_by(incident: @incident, user: @manager)
    login_as @manager
    patch update_notifications_incident_assignment_path(@incident, assignment),
      params: { status_change: "1", new_message: "0" }
    assert_redirected_to incident_path(@incident)
    assignment.reload
    assert_equal({ "status_change" => true, "new_message" => false }, assignment.notification_overrides)
  end

  test "user cannot update another user's notification overrides" do
    assignment = IncidentAssignment.find_by(incident: @incident, user: @manager)
    IncidentAssignment.create!(incident: @incident, user: @tech, assigned_by_user: @manager)
    login_as @tech
    patch update_notifications_incident_assignment_path(@incident, assignment),
      params: { status_change: "1" }
    assert_response :not_found
  end

  test "only known keys are stored in notification overrides" do
    assignment = IncidentAssignment.find_by(incident: @incident, user: @manager)
    login_as @manager
    patch update_notifications_incident_assignment_path(@incident, assignment),
      params: { status_change: "1", bogus_key: "1" }
    assignment.reload
    assert_equal({ "status_change" => true }, assignment.notification_overrides)
    assert_not assignment.notification_overrides.key?("bogus_key")
  end

  test "empty params clears notification overrides" do
    assignment = IncidentAssignment.find_by(incident: @incident, user: @manager)
    assignment.update!(notification_overrides: { "status_change" => true })
    login_as @manager
    patch update_notifications_incident_assignment_path(@incident, assignment)
    assignment.reload
    assert_equal({}, assignment.notification_overrides)
  end

  # --- Guest invite ---

  test "manager can invite a guest" do
    Organization.create!(name: "External", organization_type: "external")
    login_as @manager

    assert_difference "User.count", 1 do
      assert_difference "Invitation.count", 1 do
        assert_difference "IncidentAssignment.count", 1 do
          post guest_incident_assignments_path(@incident), params: {
            email: "adjuster@insurance.com", first_name: "Jane", last_name: "Doe", title: "Insurance Adjuster"
          }
        end
      end
    end
    assert_redirected_to incident_path(@incident)

    guest = User.find_by(email_address: "adjuster@insurance.com")
    assert_equal "guest", guest.user_type
    assert_equal "Insurance Adjuster", guest.title
    assert_not guest.active?
    assert @incident.assigned_users.include?(guest)
  end

  test "pm_user can invite a guest" do
    Organization.create!(name: "External", organization_type: "external")
    login_as @pm_user

    assert_difference "User.count", 1 do
      post guest_incident_assignments_path(@incident), params: {
        email: "owner@building.com", first_name: "Bob", last_name: "Owner", title: "Building Owner"
      }
    end
    assert_redirected_to incident_path(@incident)
  end

  test "technician cannot invite a guest" do
    Organization.create!(name: "External", organization_type: "external")
    IncidentAssignment.create!(incident: @incident, user: @tech, assigned_by_user: @manager)
    login_as @tech

    assert_no_difference "User.count" do
      post guest_incident_assignments_path(@incident), params: {
        email: "someone@example.com", first_name: "No", last_name: "Access"
      }
    end
    assert_response :not_found
  end

  test "inviting same guest email to second incident does not duplicate user" do
    Organization.create!(name: "External", organization_type: "external")
    login_as @manager

    post guest_incident_assignments_path(@incident), params: {
      email: "shared@guest.com", first_name: "Shared", last_name: "Guest"
    }

    second_incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "fire", description: "Second incident"
    )
    IncidentAssignment.create!(incident: second_incident, user: @manager, assigned_by_user: @manager)

    assert_no_difference "User.count" do
      post guest_incident_assignments_path(second_incident), params: {
        email: "shared@guest.com", first_name: "Shared", last_name: "Guest"
      }
    end
    assert_redirected_to incident_path(second_incident)

    guest = User.find_by(email_address: "shared@guest.com")
    assert_equal 2, guest.incident_assignments.count
  end

  test "manager can remove a guest assignment" do
    external = Organization.create!(name: "External", organization_type: "external")
    guest = User.create!(organization: external, user_type: "guest",
      email_address: "removeme@guest.com", first_name: "Remove", last_name: "Me", password: "password123")
    assignment = IncidentAssignment.create!(incident: @incident, user: guest, assigned_by_user: @manager)

    login_as @manager
    assert_difference "IncidentAssignment.count", -1 do
      delete incident_assignment_path(@incident, assignment)
    end
    assert_redirected_to incident_path(@incident)
  end

  test "pm_user can remove a guest assignment" do
    external = Organization.create!(name: "External", organization_type: "external")
    guest = User.create!(organization: external, user_type: "guest",
      email_address: "removeme2@guest.com", first_name: "Remove", last_name: "Me2", password: "password123")
    assignment = IncidentAssignment.create!(incident: @incident, user: guest, assigned_by_user: @manager)

    IncidentAssignment.create!(incident: @incident, user: @pm_user, assigned_by_user: @manager)
    login_as @pm_user
    assert_difference "IncidentAssignment.count", -1 do
      delete incident_assignment_path(@incident, assignment)
    end
    assert_redirected_to incident_path(@incident)
  end

  private

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end
end
