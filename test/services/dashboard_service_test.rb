require "test_helper"

class DashboardServiceTest < ActiveSupport::TestCase
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @other_pm = Organization.create!(name: "Other PM", organization_type: "property_management")

    @property = Property.create!(name: "Sunset Apts", mitigation_org: @genixo, property_management_org: @greystar)
    @other_property = Property.create!(name: "Other Bldg", mitigation_org: @genixo, property_management_org: @other_pm)

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "Test", last_name: "Tech", password: "password123")
    @pm_user = User.create!(organization: @greystar, user_type: "property_manager",
      email_address: "pm@greystar.com", first_name: "Test", last_name: "PM", password: "password123")

    PropertyAssignment.create!(user: @pm_user, property: @property)

    # Create incidents in different states
    @new_emergency = create_incident(@property, status: "new", emergency: true, last_activity_at: 30.seconds.ago)
    @active_emergency = create_incident(@property, status: "active", emergency: true, last_activity_at: 1.minute.ago)
    @active = create_incident(@property, status: "active", emergency: false, last_activity_at: 5.minutes.ago)
    @needs_attention = create_incident(@property, status: "acknowledged", emergency: false, last_activity_at: 10.minutes.ago)
    @on_hold = create_incident(@property, status: "on_hold", emergency: false, last_activity_at: 1.hour.ago)
    @completed = create_incident(@property, status: "completed", emergency: false, last_activity_at: 1.day.ago)

    # Assign tech to some incidents
    IncidentAssignment.create!(incident: @new_emergency, user: @tech, assigned_by_user: @manager)
    IncidentAssignment.create!(incident: @active_emergency, user: @tech, assigned_by_user: @manager)
    IncidentAssignment.create!(incident: @active, user: @tech, assigned_by_user: @manager)
  end

  # --- Grouping ---

  test "groups emergency incidents — only new/acknowledged, not active" do
    groups = DashboardService.new(user: @manager).grouped_incidents
    assert_includes groups[:emergency].to_a, @new_emergency
    assert_not_includes groups[:emergency].to_a, @active_emergency
  end

  test "groups active incidents — includes former emergencies" do
    groups = DashboardService.new(user: @manager).grouped_incidents
    assert_includes groups[:active].to_a, @active
    assert_includes groups[:active].to_a, @active_emergency
  end

  test "groups needs_attention incidents" do
    groups = DashboardService.new(user: @manager).grouped_incidents
    assert_includes groups[:needs_attention].to_a, @needs_attention
  end

  test "groups on_hold incidents" do
    groups = DashboardService.new(user: @manager).grouped_incidents
    assert_includes groups[:on_hold].to_a, @on_hold
  end

  test "groups completed incidents" do
    groups = DashboardService.new(user: @manager).grouped_incidents
    assert_includes groups[:recent_completed].to_a, @completed
  end

  test "sorts by last_activity_at descending" do
    groups = DashboardService.new(user: @manager).grouped_incidents
    completed2 = create_incident(@property, status: "completed", emergency: false, last_activity_at: 1.minute.ago)
    completed_list = DashboardService.new(user: @manager).grouped_incidents[:recent_completed].to_a
    assert_equal completed2.id, completed_list.first.id
  end

  # --- Role scoping ---

  test "manager sees all incidents across org properties" do
    other_incident = create_incident(@other_property, status: "active", emergency: false)
    groups = DashboardService.new(user: @manager).grouped_incidents
    assert_includes groups[:active].to_a, other_incident
  end

  test "technician sees only assigned incidents" do
    groups = DashboardService.new(user: @tech).grouped_incidents
    all_ids = groups.values.flat_map { |scope| scope.pluck(:id) }

    assert_includes all_ids, @active_emergency.id
    assert_includes all_ids, @active.id
    assert_not_includes all_ids, @needs_attention.id
    assert_not_includes all_ids, @on_hold.id
  end

  test "PM user sees incidents on assigned properties" do
    groups = DashboardService.new(user: @pm_user).grouped_incidents
    all_ids = groups.values.flat_map { |scope| scope.pluck(:id) }

    assert_includes all_ids, @active_emergency.id
    assert_includes all_ids, @active.id
    assert_includes all_ids, @needs_attention.id
  end

  test "PM user does not see incidents on unassigned properties" do
    other_incident = create_incident(@other_property, status: "active", emergency: false)
    groups = DashboardService.new(user: @pm_user).grouped_incidents
    all_ids = groups.values.flat_map { |scope| scope.pluck(:id) }

    assert_not_includes all_ids, other_incident.id
  end

  # --- Limits ---

  test "recent_completed is limited to 20" do
    25.times { create_incident(@property, status: "completed", emergency: false) }
    groups = DashboardService.new(user: @manager).grouped_incidents
    assert_equal 20, groups[:recent_completed].count
  end

  # --- Unread counts ---

  test "unread_counts returns empty hash when no messages or events" do
    counts = DashboardService.new(user: @manager).unread_counts
    assert_equal({}, counts)
  end

  test "unread_counts includes unread messages" do
    # Tech sends a message the manager hasn't read
    Message.create!(incident: @active, user: @tech, body: "Hello")

    counts = DashboardService.new(user: @manager).unread_counts
    assert_equal 1, counts.dig(@active.id, :messages)
  end

  test "unread_counts excludes own messages" do
    Message.create!(incident: @active, user: @manager, body: "My own message")

    counts = DashboardService.new(user: @manager).unread_counts
    assert_empty counts
  end

  test "unread_counts respects last_message_read_at" do
    msg1 = Message.create!(incident: @active, user: @tech, body: "Old", created_at: 1.hour.ago)
    msg2 = Message.create!(incident: @active, user: @tech, body: "New", created_at: 1.minute.ago)

    # Mark as read 30 minutes ago — msg1 is read, msg2 is unread
    IncidentReadState.create!(incident: @active, user: @manager, last_message_read_at: 30.minutes.ago)

    counts = DashboardService.new(user: @manager).unread_counts
    assert_equal 1, counts.dig(@active.id, :messages)
  end

  test "unread_counts includes unread activity events" do
    ActivityEvent.create!(
      incident: @active, performed_by_user: @tech,
      event_type: "activity_logged", metadata: {}
    )

    counts = DashboardService.new(user: @manager).unread_counts
    assert_equal 1, counts.dig(@active.id, :activity)
  end

  test "unread_counts excludes non-daily-log activity events" do
    ActivityEvent.create!(
      incident: @active, performed_by_user: @tech,
      event_type: "status_changed", metadata: {}
    )

    counts = DashboardService.new(user: @manager).unread_counts
    assert_nil counts.dig(@active.id, :activity)
  end

  test "unread_counts respects last_activity_read_at" do
    ActivityEvent.create!(
      incident: @active, performed_by_user: @tech,
      event_type: "activity_logged", metadata: {}, created_at: 1.hour.ago
    )
    ActivityEvent.create!(
      incident: @active, performed_by_user: @tech,
      event_type: "activity_logged", metadata: {}, created_at: 1.minute.ago
    )
    ActivityEvent.create!(
      incident: @active, performed_by_user: @tech,
      event_type: "status_changed", metadata: {}, created_at: 30.seconds.ago
    )

    IncidentReadState.create!(incident: @active, user: @manager, last_activity_read_at: 30.minutes.ago)

    counts = DashboardService.new(user: @manager).unread_counts
    assert_equal 1, counts.dig(@active.id, :activity)
  end

  test "technician only sees unread counts for assigned incidents" do
    Message.create!(incident: @active, user: @manager, body: "For tech")
    Message.create!(incident: @needs_attention, user: @manager, body: "Not for tech")

    counts = DashboardService.new(user: @tech).unread_counts
    assert counts.key?(@active.id)
    assert_not counts.key?(@needs_attention.id)
  end

  private

  def create_incident(property, status:, emergency:, last_activity_at: Time.current)
    Incident.create!(
      property: property, created_by_user: @manager,
      status: status, project_type: "emergency_response",
      damage_type: "flood", description: "Test", emergency: emergency,
      last_activity_at: last_activity_at
    )
  end
end
