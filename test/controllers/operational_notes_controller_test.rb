require "test_helper"

class OperationalNotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @sandalwood = Organization.create!(name: "Sandalwood", organization_type: "property_management")

    @property = Property.create!(
      name: "Sunset Apartments", property_management_org: @greystar,
      mitigation_org: @genixo
    )

    @manager = User.create!(organization: @genixo, user_type: User::MANAGER,
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: User::TECHNICIAN,
      email_address: "tech@genixo.com", first_name: "Test", last_name: "Tech", password: "password123")
    @office_sales = User.create!(organization: @genixo, user_type: User::OFFICE_SALES,
      email_address: "sales@genixo.com", first_name: "Test", last_name: "Sales", password: "password123")
    @pm_user = User.create!(organization: @greystar, user_type: User::PROPERTY_MANAGER,
      email_address: "pm@greystar.com", first_name: "Test", last_name: "PM", password: "password123")
    @cross_org_pm = User.create!(organization: @sandalwood, user_type: User::PROPERTY_MANAGER,
      email_address: "pm@sandalwood.com", first_name: "Cross", last_name: "PM", password: "password123")

    PropertyAssignment.create!(user: @pm_user, property: @property)

    @incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "flood", description: "Test incident", emergency: true
    )
    IncidentAssignment.create!(incident: @incident, user: @tech, assigned_by_user: @manager)
  end

  # --- Create tests ---

  test "manager can create operational note" do
    login_as @manager
    assert_difference "OperationalNote.count", 1 do
      post incident_operational_notes_path(@incident), params: {
        operational_note: { note_text: "Performed air duct cleaning to unit 238", log_date: Date.current }
      }
    end
    assert_redirected_to incident_path(@incident)
    note = OperationalNote.last
    assert_equal "Performed air duct cleaning to unit 238", note.note_text
    assert_equal @manager.id, note.created_by_user_id
  end

  test "tech can create operational note" do
    login_as @tech
    assert_difference "OperationalNote.count", 1 do
      post incident_operational_notes_path(@incident), params: {
        operational_note: { note_text: "Set up containment barriers", log_date: Date.current }
      }
    end
    assert_redirected_to incident_path(@incident)
    assert_equal @tech.id, OperationalNote.last.created_by_user_id
  end

  test "office_sales cannot create operational note" do
    login_as @office_sales
    assert_no_difference "OperationalNote.count" do
      post incident_operational_notes_path(@incident), params: {
        operational_note: { note_text: "Should not work", log_date: Date.current }
      }
    end
    assert_response :not_found
  end

  test "PM user cannot create operational note" do
    login_as @pm_user
    assert_no_difference "OperationalNote.count" do
      post incident_operational_notes_path(@incident), params: {
        operational_note: { note_text: "Should not work", log_date: Date.current }
      }
    end
    assert_response :not_found
  end

  test "cross-org PM user cannot create operational note" do
    login_as @cross_org_pm
    assert_no_difference "OperationalNote.count" do
      post incident_operational_notes_path(@incident), params: {
        operational_note: { note_text: "Should not work", log_date: Date.current }
      }
    end
    assert_response :not_found
  end

  # --- Activity event + validation tests ---

  test "creates activity event and touches last_activity_at" do
    login_as @manager
    assert_difference "ActivityEvent.count", 1 do
      post incident_operational_notes_path(@incident), params: {
        operational_note: { note_text: "Checked moisture levels in bedroom", log_date: Date.current }
      }
    end
    event = ActivityEvent.last
    assert_equal "operational_note_added", event.event_type
    assert_equal @manager.id, event.performed_by_user_id
    assert event.metadata["note_preview"].present?
    assert_not_nil @incident.reload.last_activity_at
  end

  test "returns error when note_text is blank" do
    login_as @manager
    assert_no_difference "OperationalNote.count" do
      post incident_operational_notes_path(@incident), params: {
        operational_note: { note_text: "", log_date: Date.current }
      }
    end
    assert_redirected_to incident_path(@incident)
    assert_equal "Could not add note.", flash[:alert]
  end

  private

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end
end
