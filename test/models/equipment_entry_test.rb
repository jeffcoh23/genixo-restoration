require "test_helper"

class EquipmentEntryTest < ActiveSupport::TestCase
  setup do
    genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    property = Property.create!(name: "Test Property", property_management_org: greystar, mitigation_org: genixo)
    @logger = User.create!(organization: genixo, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "T", last_name: "T", password: "password123")
    @incident = Incident.create!(property: property, created_by_user: @logger,
      status: "active", project_type: "emergency_response", damage_type: "flood",
      description: "Test", emergency: true)
    @type = EquipmentType.create!(name: "Air Mover", organization: genixo)
  end

  test "accepts entry with no removed_at (equipment still on-site)" do
    entry = EquipmentEntry.new(
      incident: @incident, logged_by_user: @logger, equipment_type: @type,
      placed_at: 2.hours.ago, removed_at: nil
    )
    assert entry.valid?, "expected valid, got #{entry.errors.full_messages.inspect}"
  end

  test "rejects removed_at equal to placed_at" do
    same = Time.zone.parse("2026-04-22 10:00:00")
    entry = EquipmentEntry.new(
      incident: @incident, logged_by_user: @logger, equipment_type: @type,
      placed_at: same, removed_at: same
    )
    assert_not entry.valid?
    assert_includes entry.errors[:removed_at], "must be after placed time"
  end

  test "rejects removed_at earlier than placed_at" do
    entry = EquipmentEntry.new(
      incident: @incident, logged_by_user: @logger, equipment_type: @type,
      placed_at: 2.hours.ago, removed_at: 3.hours.ago
    )
    assert_not entry.valid?
    assert_includes entry.errors[:removed_at], "must be after placed time"
  end

  test "accepts removed_at after placed_at" do
    entry = EquipmentEntry.new(
      incident: @incident, logged_by_user: @logger, equipment_type: @type,
      placed_at: 3.hours.ago, removed_at: 1.hour.ago
    )
    assert entry.valid?, "expected valid, got #{entry.errors.full_messages.inspect}"
  end
end
