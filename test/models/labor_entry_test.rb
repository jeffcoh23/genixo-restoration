require "test_helper"

class LaborEntryTest < ActiveSupport::TestCase
  setup do
    genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    property = Property.create!(name: "Test Property", property_management_org: greystar, mitigation_org: genixo)
    @creator = User.create!(organization: genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "T", last_name: "M", password: "password123")
    @incident = Incident.create!(property: property, created_by_user: @creator,
      status: "active", project_type: "emergency_response", damage_type: "flood",
      description: "Test", emergency: true)
  end

  test "rejects end time equal to start time" do
    same = Time.zone.parse("2026-04-22 10:00:00")
    entry = LaborEntry.new(
      incident: @incident, created_by_user: @creator, role_label: "Tech",
      log_date: Date.current, started_at: same, ended_at: same, hours: 0
    )
    assert_not entry.valid?
    assert_includes entry.errors[:ended_at], "must be after start time"
  end

  test "rejects end time before start time" do
    started = Time.zone.parse("2026-04-22 10:00:00")
    ended = Time.zone.parse("2026-04-22 09:00:00")
    entry = LaborEntry.new(
      incident: @incident, created_by_user: @creator, role_label: "Tech",
      log_date: Date.current, started_at: started, ended_at: ended, hours: -1
    )
    assert_not entry.valid?
    assert_includes entry.errors[:ended_at], "must be after start time"
  end

  test "accepts end time after start time" do
    started = Time.zone.parse("2026-04-22 10:00:00")
    ended = Time.zone.parse("2026-04-22 12:00:00")
    entry = LaborEntry.new(
      incident: @incident, created_by_user: @creator, role_label: "Tech",
      log_date: Date.current, started_at: started, ended_at: ended, hours: 2
    )
    assert entry.valid?, "expected valid, got #{entry.errors.full_messages.inspect}"
  end
end
