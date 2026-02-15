require "test_helper"

class ActivityLoggerTest < ActiveSupport::TestCase
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @property = Property.create!(name: "Test Bldg", mitigation_org: @genixo, property_management_org: @greystar)
    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @incident = Incident.create!(property: @property, created_by_user: @manager,
      status: "acknowledged", project_type: "emergency_response", damage_type: "flood",
      description: "Water damage in unit 100", emergency: true)
  end

  test "creates an activity event on the incident" do
    assert_difference "ActivityEvent.count", 1 do
      ActivityLogger.log(incident: @incident, event_type: "incident_created", user: @manager)
    end

    event = ActivityEvent.last
    assert_equal "incident_created", event.event_type
    assert_equal @manager.id, event.performed_by_user_id
    assert_equal @incident.id, event.incident_id
  end

  test "stores metadata on the event" do
    ActivityLogger.log(
      incident: @incident, event_type: "status_changed", user: @manager,
      metadata: { old_status: "new", new_status: "acknowledged" }
    )

    event = ActivityEvent.last
    assert_equal "new", event.metadata["old_status"]
    assert_equal "acknowledged", event.metadata["new_status"]
  end

  test "touches last_activity_at on the incident" do
    @incident.update_column(:last_activity_at, 1.hour.ago)
    before = @incident.last_activity_at

    ActivityLogger.log(incident: @incident, event_type: "incident_created", user: @manager)

    assert @incident.reload.last_activity_at > before
  end

  test "raises on invalid event_type" do
    assert_raises ActiveRecord::RecordInvalid do
      ActivityLogger.log(incident: @incident, event_type: "invalid_type", user: @manager)
    end
  end
end
