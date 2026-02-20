require "test_helper"

class EquipmentItemTest < ActiveSupport::TestCase
  setup do
    @org = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @type = EquipmentType.create!(name: "Dehumidifier", organization: @org)
  end

  test "valid with required fields" do
    item = EquipmentItem.new(equipment_type: @type, organization: @org, identifier: "DH-001")
    assert item.valid?
  end

  test "requires identifier" do
    item = EquipmentItem.new(equipment_type: @type, organization: @org, identifier: "")
    assert_not item.valid?
    assert item.errors[:identifier].present?
  end

  test "requires equipment type" do
    item = EquipmentItem.new(organization: @org, identifier: "DH-001")
    item.equipment_type = nil
    assert_not item.valid?
  end

  test "identifier must be unique within org" do
    EquipmentItem.create!(equipment_type: @type, organization: @org, identifier: "DH-001")
    duplicate = EquipmentItem.new(equipment_type: @type, organization: @org, identifier: "DH-001")
    assert_not duplicate.valid?
    assert duplicate.errors[:identifier].present?
  end

  test "same identifier allowed in different orgs" do
    other_org = Organization.create!(name: "Other Co", organization_type: "mitigation")
    other_type = EquipmentType.create!(name: "Dehumidifier", organization: other_org)
    EquipmentItem.create!(equipment_type: @type, organization: @org, identifier: "DH-001")
    item = EquipmentItem.new(equipment_type: other_type, organization: other_org, identifier: "DH-001")
    assert item.valid?
  end

  test "active scope" do
    active = EquipmentItem.create!(equipment_type: @type, organization: @org, identifier: "DH-001", active: true)
    inactive = EquipmentItem.create!(equipment_type: @type, organization: @org, identifier: "DH-002", active: false)

    assert_includes EquipmentItem.active, active
    assert_not_includes EquipmentItem.active, inactive
  end
end
