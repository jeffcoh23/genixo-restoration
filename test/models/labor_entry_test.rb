require "test_helper"

class LaborEntryTest < ActiveSupport::TestCase
  setup do
    mitigation_org = Organization.create!(name: "Labor Mitigation", organization_type: "mitigation")
    pm_org = Organization.create!(name: "Labor PM", organization_type: "property_management")
    property = Property.create!(
      name: "Labor Property",
      mitigation_org: mitigation_org,
      property_management_org: pm_org
    )
    @manager = User.create!(
      organization: mitigation_org, user_type: "manager",
      email_address: "labor-manager@example.com", first_name: "Labor", last_name: "Manager",
      password: "password123"
    )
    @office_sales = User.create!(
      organization: mitigation_org, user_type: "office_sales",
      email_address: "labor-office@example.com", first_name: "Labor", last_name: "Office",
      password: "password123"
    )
    @pm_user = User.create!(
      organization: pm_org, user_type: "property_manager",
      email_address: "labor-pm@example.com", first_name: "Labor", last_name: "PM",
      password: "password123"
    )
    @incident = Incident.create!(
      property: property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "flood", description: "Labor validation"
    )
  end

  test "allows labor attributed to an eligible mitigation worker" do
    entry = build_entry(user: @manager)

    assert entry.valid?
  end

  test "allows generic labor without a user" do
    entry = build_entry(user: nil)

    assert entry.valid?
  end

  test "rejects labor attributed to a user outside the mitigation organization" do
    entry = build_entry(user: @pm_user)

    assert_not entry.valid?
    assert_equal [ "must be an eligible mitigation worker" ], entry.errors[:user]
  end

  test "rejects labor attributed to an ineligible mitigation role" do
    entry = build_entry(user: @office_sales)

    assert_not entry.valid?
    assert_equal [ "must be an eligible mitigation worker" ], entry.errors[:user]
  end

  test "rejects end time equal to start time" do
    same = Time.zone.parse("2026-04-22 10:00:00")
    entry = LaborEntry.new(
      incident: @incident, created_by_user: @manager, role_label: "Tech",
      log_date: Date.current, started_at: same, ended_at: same, hours: 0
    )

    assert_not entry.valid?
    assert_includes entry.errors[:ended_at], "must be after start time"
  end

  test "rejects end time before start time" do
    started = Time.zone.parse("2026-04-22 10:00:00")
    ended = Time.zone.parse("2026-04-22 09:00:00")
    entry = LaborEntry.new(
      incident: @incident, created_by_user: @manager, role_label: "Tech",
      log_date: Date.current, started_at: started, ended_at: ended, hours: -1
    )

    assert_not entry.valid?
    assert_includes entry.errors[:ended_at], "must be after start time"
  end

  test "accepts end time after start time" do
    started = Time.zone.parse("2026-04-22 10:00:00")
    ended = Time.zone.parse("2026-04-22 12:00:00")
    entry = LaborEntry.new(
      incident: @incident, created_by_user: @manager, role_label: "Tech",
      log_date: Date.current, started_at: started, ended_at: ended, hours: 2
    )

    assert entry.valid?, "expected valid, got #{entry.errors.full_messages.inspect}"
  end

  private

  def build_entry(user:)
    @incident.labor_entries.build(
      user: user,
      created_by_user: @manager,
      role_label: "Technician",
      log_date: Date.current,
      started_at: Time.current.beginning_of_day + 8.hours,
      ended_at: Time.current.beginning_of_day + 10.hours,
      hours: 2
    )
  end
end
