require "test_helper"

class IncidentCreationServiceTest < ActiveSupport::TestCase
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")

    @property = Property.create!(name: "Sunset Apts", mitigation_org: @genixo, property_management_org: @greystar)

    # Mitigation users
    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @office = User.create!(organization: @genixo, user_type: "office_sales",
      email_address: "office@genixo.com", first_name: "Test", last_name: "Office", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "Test", last_name: "Tech", password: "password123")

    # PM users
    @pm_user = User.create!(organization: @greystar, user_type: "property_manager",
      email_address: "pm@greystar.com", first_name: "Test", last_name: "PM", password: "password123")
    @area_mgr = User.create!(organization: @greystar, user_type: "area_manager",
      email_address: "am@greystar.com", first_name: "Test", last_name: "AreaMgr", password: "password123")
    @pm_manager = User.create!(organization: @greystar, user_type: "pm_manager",
      email_address: "pmmgr@greystar.com", first_name: "Test", last_name: "PMMgr", password: "password123")

    # Assign PM users to property
    PropertyAssignment.create!(user: @pm_user, property: @property)
    PropertyAssignment.create!(user: @area_mgr, property: @property)
  end

  # --- Status transitions per project type ---

  test "emergency_response creates incident with acknowledged status and emergency flag" do
    incident = create_incident(project_type: "emergency_response")

    assert_equal "acknowledged", incident.status
    assert incident.emergency
  end

  test "mitigation_rfq creates incident with proposal_requested status" do
    incident = create_incident(project_type: "mitigation_rfq")

    assert_equal "proposal_requested", incident.status
    assert_not incident.emergency
  end

  test "buildback_rfq creates incident with proposal_requested status" do
    incident = create_incident(project_type: "buildback_rfq")

    assert_equal "proposal_requested", incident.status
    assert_not incident.emergency
  end

  test "other creates incident with acknowledged status" do
    incident = create_incident(project_type: "other")

    assert_equal "acknowledged", incident.status
    assert_not incident.emergency
  end

  # --- Auto-assignment ---

  test "auto-assigns property-assigned PM users" do
    incident = create_incident
    assigned_ids = incident.incident_assignments.pluck(:user_id)

    assert_includes assigned_ids, @pm_user.id
    assert_includes assigned_ids, @area_mgr.id
  end

  test "auto-assigns pm_managers from the PM org" do
    incident = create_incident
    assigned_ids = incident.incident_assignments.pluck(:user_id)

    assert_includes assigned_ids, @pm_manager.id
  end

  test "auto-assigns mitigation managers and office_sales" do
    incident = create_incident
    assigned_ids = incident.incident_assignments.pluck(:user_id)

    assert_includes assigned_ids, @manager.id
    assert_includes assigned_ids, @office.id
  end

  test "does not auto-assign technicians" do
    incident = create_incident
    assigned_ids = incident.incident_assignments.pluck(:user_id)

    assert_not_includes assigned_ids, @tech.id
  end

  test "does not auto-assign inactive users" do
    @pm_user.update!(active: false)
    incident = create_incident
    assigned_ids = incident.incident_assignments.pluck(:user_id)

    assert_not_includes assigned_ids, @pm_user.id
  end

  test "does not auto-assign PM users not assigned to the property" do
    unassigned_pm = User.create!(organization: @greystar, user_type: "property_manager",
      email_address: "other_pm@greystar.com", first_name: "Other", last_name: "PM", password: "password123")

    incident = create_incident
    assigned_ids = incident.incident_assignments.pluck(:user_id)

    assert_not_includes assigned_ids, unassigned_pm.id
  end

  # --- Activity events ---

  test "creates incident_created and status_changed activity events" do
    assert_difference "ActivityEvent.count", 2 do
      create_incident
    end

    events = ActivityEvent.last(2)
    assert_equal "incident_created", events.first.event_type
    assert_equal "status_changed", events.second.event_type
  end

  test "sets last_activity_at on the incident" do
    incident = create_incident

    assert_not_nil incident.last_activity_at
  end

  # --- Validation failure ---

  test "rolls back on validation failure" do
    assert_no_difference [ "Incident.count", "IncidentAssignment.count", "ActivityEvent.count" ] do
      assert_raises ActiveRecord::RecordInvalid do
        create_incident(description: "")
      end
    end
  end

  # --- Additional user assignment ---

  test "assigns additional users by id" do
    incident = create_incident(additional_user_ids: [ @tech.id ])
    assigned_ids = incident.incident_assignments.pluck(:user_id)

    assert_includes assigned_ids, @tech.id
  end

  test "does not duplicate auto-assigned users when passed as additional" do
    incident = create_incident(additional_user_ids: [ @manager.id ])
    assignment_count = incident.incident_assignments.where(user_id: @manager.id).count

    assert_equal 1, assignment_count
  end

  test "skips inactive users in additional_user_ids" do
    @tech.update!(active: false)
    incident = create_incident(additional_user_ids: [ @tech.id ])
    assigned_ids = incident.incident_assignments.pluck(:user_id)

    assert_not_includes assigned_ids, @tech.id
  end

  # --- Contacts ---

  test "creates contacts from params" do
    incident = create_incident(contacts: [
      { name: "John Doe", title: "Building Super", email: "john@example.com", phone: "555-0100" }
    ])

    assert_equal 1, incident.incident_contacts.count
    contact = incident.incident_contacts.first
    assert_equal "John Doe", contact.name
    assert_equal "Building Super", contact.title
    assert_equal "john@example.com", contact.email
    assert_equal "555-0100", contact.phone
  end

  test "skips contacts with blank name" do
    incident = create_incident(contacts: [
      { name: "", title: "Nobody", email: "", phone: "" },
      { name: "Real Contact", title: "", email: "", phone: "" }
    ])

    assert_equal 1, incident.incident_contacts.count
    assert_equal "Real Contact", incident.incident_contacts.first.name
  end

  test "creates incident without additional_user_ids or contacts" do
    incident = create_incident
    assert incident.persisted?
  end

  # --- Core attributes ---

  test "stores optional fields" do
    incident = create_incident(
      cause: "Pipe burst",
      requested_next_steps: "Send crew ASAP",
      units_affected: 3,
      affected_room_numbers: "101, 102, 103"
    )

    assert_equal "Pipe burst", incident.cause
    assert_equal "Send crew ASAP", incident.requested_next_steps
    assert_equal 3, incident.units_affected
    assert_equal "101, 102, 103", incident.affected_room_numbers
  end

  private

  def create_incident(overrides = {})
    params = {
      project_type: "emergency_response",
      damage_type: "flood",
      description: "Water damage in unit 100"
    }.merge(overrides)

    IncidentCreationService.new(property: @property, user: @manager, params: params).call
  end
end
