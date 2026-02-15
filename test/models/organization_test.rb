require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  test "valid mitigation org" do
    org = Organization.new(name: "Test Mitigation", organization_type: "mitigation")
    assert org.valid?
    assert org.mitigation?
    assert_not org.property_management?
  end

  test "valid property management org" do
    org = Organization.new(name: "Test PM", organization_type: "property_management")
    assert org.valid?
    assert org.property_management?
    assert_not org.mitigation?
  end

  test "requires name" do
    org = Organization.new(organization_type: "mitigation")
    assert_not org.valid?
    assert_includes org.errors[:name], "can't be blank"
  end

  test "requires organization_type" do
    org = Organization.new(name: "Test")
    assert_not org.valid?
    assert_includes org.errors[:organization_type], "can't be blank"
  end

  test "rejects invalid organization_type" do
    org = Organization.new(name: "Test", organization_type: "invalid")
    assert_not org.valid?
    assert_includes org.errors[:organization_type], "is not included in the list"
  end
end
