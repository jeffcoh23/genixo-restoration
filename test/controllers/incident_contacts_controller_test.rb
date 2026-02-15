require "test_helper"

class IncidentContactsControllerTest < ActionDispatch::IntegrationTest
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
    @pm_user = User.create!(organization: @greystar, user_type: "property_manager",
      email_address: "pm@greystar.com", first_name: "Test", last_name: "PM", password: "password123")

    PropertyAssignment.create!(user: @pm_user, property: @property)

    @incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "flood", description: "Test incident", emergency: true
    )
    IncidentAssignment.create!(incident: @incident, user: @tech, assigned_by_user: @manager)
  end

  test "manager can add a contact" do
    login_as @manager
    assert_difference "IncidentContact.count", 1 do
      assert_difference "ActivityEvent.count", 1 do
        post incident_contacts_path(@incident), params: {
          contact: { name: "Bob Smith", title: "Insurance Adjuster", email: "bob@ins.com", phone: "555-0123" }
        }
      end
    end
    assert_redirected_to incident_path(@incident)
    contact = IncidentContact.last
    assert_equal "Bob Smith", contact.name
    assert_equal "Insurance Adjuster", contact.title
  end

  test "pm_user can add a contact" do
    login_as @pm_user
    assert_difference "IncidentContact.count", 1 do
      post incident_contacts_path(@incident), params: {
        contact: { name: "Jane Owner", email: "jane@owner.com" }
      }
    end
    assert_redirected_to incident_path(@incident)
  end

  test "technician cannot add a contact" do
    login_as @tech
    post incident_contacts_path(@incident), params: {
      contact: { name: "Should Not Work" }
    }
    assert_response :not_found
  end

  test "add contact fails without name" do
    login_as @manager
    assert_no_difference "IncidentContact.count" do
      post incident_contacts_path(@incident), params: {
        contact: { name: "", email: "test@example.com" }
      }
    end
    assert_redirected_to incident_path(@incident)
  end

  test "manager can remove a contact" do
    contact = @incident.incident_contacts.create!(
      name: "Bob Smith", created_by_user: @manager
    )
    login_as @manager
    assert_difference "IncidentContact.count", -1 do
      assert_difference "ActivityEvent.count", 1 do
        delete incident_contact_path(@incident, contact)
      end
    end
    assert_redirected_to incident_path(@incident)
  end

  test "pm_user can remove a contact" do
    contact = @incident.incident_contacts.create!(
      name: "Bob Smith", created_by_user: @manager
    )
    login_as @pm_user
    assert_difference "IncidentContact.count", -1 do
      delete incident_contact_path(@incident, contact)
    end
    assert_redirected_to incident_path(@incident)
  end

  test "technician cannot remove a contact" do
    contact = @incident.incident_contacts.create!(
      name: "Bob Smith", created_by_user: @manager
    )
    login_as @tech
    delete incident_contact_path(@incident, contact)
    assert_response :not_found
    assert IncidentContact.exists?(id: contact.id)
  end

  test "activity event logged on contact add" do
    login_as @manager
    post incident_contacts_path(@incident), params: {
      contact: { name: "Bob Smith", title: "Adjuster" }
    }
    event = ActivityEvent.last
    assert_equal "contact_added", event.event_type
    assert_equal "Bob Smith", event.metadata["contact_name"]
  end

  private

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end
end
