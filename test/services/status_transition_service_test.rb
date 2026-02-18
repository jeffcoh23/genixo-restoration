require "test_helper"

class StatusTransitionServiceTest < ActiveSupport::TestCase
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @property = Property.create!(name: "Test Bldg", mitigation_org: @genixo, property_management_org: @greystar)
    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
  end

  # --- Valid transitions ---

  test "acknowledged to active" do
    incident = create_incident(status: "acknowledged")
    transition(incident, "active")
    assert_equal "active", incident.reload.status
  end

  test "acknowledged to on_hold" do
    incident = create_incident(status: "acknowledged")
    transition(incident, "on_hold")
    assert_equal "on_hold", incident.reload.status
  end

  # --- Quote-type transitions ---

  test "proposal_requested to proposal_submitted" do
    incident = create_quote_incident(status: "proposal_requested")
    transition(incident, "proposal_submitted")
    assert_equal "proposal_submitted", incident.reload.status
  end

  test "proposal_submitted to proposal_signed" do
    incident = create_quote_incident(status: "proposal_submitted")
    transition(incident, "proposal_signed")
    assert_equal "proposal_signed", incident.reload.status
  end

  test "proposal_signed to active" do
    incident = create_quote_incident(status: "proposal_signed")
    transition(incident, "active")
    assert_equal "active", incident.reload.status
  end

  test "quote active to completed" do
    incident = create_quote_incident(status: "active")
    transition(incident, "completed")
    assert_equal "completed", incident.reload.status
  end

  test "active to on_hold" do
    incident = create_incident(status: "active")
    transition(incident, "on_hold")
    assert_equal "on_hold", incident.reload.status
  end

  test "active to completed" do
    incident = create_incident(status: "active")
    transition(incident, "completed")
    assert_equal "completed", incident.reload.status
  end

  test "on_hold to active" do
    incident = create_incident(status: "on_hold")
    transition(incident, "active")
    assert_equal "active", incident.reload.status
  end

  test "on_hold to completed" do
    incident = create_incident(status: "on_hold")
    transition(incident, "completed")
    assert_equal "completed", incident.reload.status
  end

  test "completed to completed_billed" do
    incident = create_incident(status: "completed")
    transition(incident, "completed_billed")
    assert_equal "completed_billed", incident.reload.status
  end

  test "completed to active (reopen)" do
    incident = create_incident(status: "completed")
    transition(incident, "active")
    assert_equal "active", incident.reload.status
  end

  test "completed_billed to paid" do
    incident = create_incident(status: "completed_billed")
    transition(incident, "paid")
    assert_equal "paid", incident.reload.status
  end

  test "completed_billed to active (reopen)" do
    incident = create_incident(status: "completed_billed")
    transition(incident, "active")
    assert_equal "active", incident.reload.status
  end

  test "paid to closed" do
    incident = create_incident(status: "paid")
    transition(incident, "closed")
    assert_equal "closed", incident.reload.status
  end

  # --- Invalid transitions ---

  test "cannot transition from new" do
    incident = create_incident(status: "new")
    assert_raises(StatusTransitionService::InvalidTransitionError) { transition(incident, "active") }
    assert_equal "new", incident.reload.status
  end

  test "cannot transition from closed" do
    incident = create_incident(status: "closed")
    assert_raises(StatusTransitionService::InvalidTransitionError) { transition(incident, "active") }
    assert_equal "closed", incident.reload.status
  end

  test "cannot skip from acknowledged to completed" do
    incident = create_incident(status: "acknowledged")
    assert_raises(StatusTransitionService::InvalidTransitionError) { transition(incident, "completed") }
    assert_equal "acknowledged", incident.reload.status
  end

  test "cannot transition active to active" do
    incident = create_incident(status: "active")
    assert_raises(StatusTransitionService::InvalidTransitionError) { transition(incident, "active") }
  end

  # --- Activity logging ---

  test "creates a status_changed activity event" do
    incident = create_incident(status: "acknowledged")

    assert_difference "ActivityEvent.count", 1 do
      transition(incident, "active")
    end

    event = ActivityEvent.last
    assert_equal "status_changed", event.event_type
    assert_equal "acknowledged", event.metadata["old_status"]
    assert_equal "active", event.metadata["new_status"]
    assert_equal @manager.id, event.performed_by_user_id
  end

  test "touches last_activity_at" do
    incident = create_incident(status: "acknowledged")
    incident.update_column(:last_activity_at, 1.hour.ago)
    before = incident.last_activity_at

    transition(incident, "active")

    assert incident.reload.last_activity_at > before
  end

  # --- Escalation resolution ---

  test "resolves pending escalation events when transitioning to active" do
    incident = create_incident(status: "acknowledged", emergency: true)

    escalation = EscalationEvent.create!(
      incident: incident, user: @manager, contact_method: "sms",
      status: "sent", attempted_at: 5.minutes.ago
    )

    transition(incident, "active")

    escalation.reload
    assert_not_nil escalation.resolved_at
    assert_equal @manager.id, escalation.resolved_by_user_id
    assert_equal "incident_marked_active", escalation.resolution_reason
  end

  test "does not resolve already-resolved escalation events" do
    incident = create_incident(status: "acknowledged", emergency: true)
    resolved_at = 10.minutes.ago

    escalation = EscalationEvent.create!(
      incident: incident, user: @manager, contact_method: "sms",
      status: "sent", attempted_at: 15.minutes.ago,
      resolved_at: resolved_at, resolved_by_user: @manager, resolution_reason: "manual"
    )

    transition(incident, "active")

    assert_equal resolved_at.to_i, escalation.reload.resolved_at.to_i
    assert_equal "manual", escalation.resolution_reason
  end

  test "does not resolve escalations on non-active transitions" do
    incident = create_incident(status: "acknowledged", emergency: true)

    escalation = EscalationEvent.create!(
      incident: incident, user: @manager, contact_method: "sms",
      status: "sent", attempted_at: 5.minutes.ago
    )

    transition(incident, "on_hold")

    assert_nil escalation.reload.resolved_at
  end

  # --- Rollback on failure ---

  test "rolls back on failure" do
    incident = create_incident(status: "acknowledged")

    assert_no_difference "ActivityEvent.count" do
      assert_raises(StatusTransitionService::InvalidTransitionError) do
        transition(incident, "completed")
      end
    end
  end

  private

  def create_incident(status:, emergency: false)
    Incident.create!(
      property: @property, created_by_user: @manager,
      status: status, project_type: "emergency_response",
      damage_type: "flood", description: "Test incident", emergency: emergency
    )
  end

  def create_quote_incident(status:)
    Incident.create!(
      property: @property, created_by_user: @manager,
      status: status, project_type: "mitigation_rfq",
      damage_type: "flood", description: "Test quote incident"
    )
  end

  def transition(incident, new_status)
    StatusTransitionService.new(incident: incident, new_status: new_status, user: @manager).call
  end
end
