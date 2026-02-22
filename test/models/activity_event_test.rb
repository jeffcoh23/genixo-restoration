require "test_helper"

class ActivityEventTest < ActiveSupport::TestCase
  setup do
    @mitigation = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @pm = Organization.create!(name: "Greystar", organization_type: "property_management")
    @property = Property.create!(name: "River Oaks", mitigation_org: @mitigation, property_management_org: @pm)

    @manager = User.create!(
      organization: @mitigation,
      user_type: User::MANAGER,
      email_address: "manager@example.com",
      first_name: "Mia",
      last_name: "Manager",
      password: "password123"
    )
    @tech = User.create!(
      organization: @mitigation,
      user_type: User::TECHNICIAN,
      email_address: "tech@example.com",
      first_name: "Tina",
      last_name: "Tech",
      password: "password123"
    )

    @incident = Incident.create!(
      property: @property,
      created_by_user: @manager,
      status: "active",
      project_type: "emergency_response",
      damage_type: "flood",
      description: "Water intrusion"
    )
  end

  test "is valid for supported event types" do
    event = ActivityEvent.new(
      incident: @incident,
      performed_by_user: @manager,
      event_type: "activity_logged",
      metadata: { title: "Moisture readings" }
    )

    assert event.valid?
  end

  test "is invalid for unsupported event types" do
    event = ActivityEvent.new(
      incident: @incident,
      performed_by_user: @manager,
      event_type: "totally_invalid",
      metadata: {}
    )

    assert_not event.valid?
    assert_includes event.errors[:event_type], "is not included in the list"
  end

  test "daily log notifications scope only includes activity_logged" do
    included = ActivityEvent.create!(
      incident: @incident,
      performed_by_user: @tech,
      event_type: "activity_logged",
      metadata: {}
    )
    excluded_status = ActivityEvent.create!(
      incident: @incident,
      performed_by_user: @tech,
      event_type: "status_changed",
      metadata: { old_status: "acknowledged", new_status: "active" }
    )
    excluded_activity_update = ActivityEvent.create!(
      incident: @incident,
      performed_by_user: @tech,
      event_type: "activity_updated",
      metadata: { title: "Adjusted dehu placement" }
    )

    scoped_ids = ActivityEvent.for_daily_log_notifications.pluck(:id)

    assert_includes scoped_ids, included.id
    assert_not_includes scoped_ids, excluded_status.id
    assert_not_includes scoped_ids, excluded_activity_update.id
  end
end
