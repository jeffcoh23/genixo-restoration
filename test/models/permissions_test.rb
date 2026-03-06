require "test_helper"

class PermissionsTest < ActiveSupport::TestCase
  # --- Manager (mitigation) ---

  test "manager has all permissions" do
    assert Permissions.has?("manager", Permissions::CREATE_INCIDENT)
    assert Permissions.has?("manager", Permissions::TRANSITION_STATUS)
    assert Permissions.has?("manager", Permissions::CREATE_PROPERTY)
    assert Permissions.has?("manager", Permissions::VIEW_PROPERTIES)
    assert Permissions.has?("manager", Permissions::MANAGE_ORGANIZATIONS)
    assert Permissions.has?("manager", Permissions::MANAGE_USERS)
    assert Permissions.has?("manager", Permissions::MANAGE_ON_CALL)
    assert Permissions.has?("manager", Permissions::MANAGE_EQUIPMENT_TYPES)
  end

  # --- Office/Sales (mitigation) ---

  test "office_sales has create, view, manage orgs/users but not transitions or on-call" do
    assert Permissions.has?("office_sales", Permissions::CREATE_INCIDENT)
    assert Permissions.has?("office_sales", Permissions::CREATE_PROPERTY)
    assert Permissions.has?("office_sales", Permissions::VIEW_PROPERTIES)
    assert Permissions.has?("office_sales", Permissions::MANAGE_ORGANIZATIONS)
    assert Permissions.has?("office_sales", Permissions::MANAGE_USERS)

    assert_not Permissions.has?("office_sales", Permissions::TRANSITION_STATUS)
    assert_not Permissions.has?("office_sales", Permissions::MANAGE_ON_CALL)
    assert_not Permissions.has?("office_sales", Permissions::MANAGE_EQUIPMENT_TYPES)
  end

  # --- Technician (mitigation) ---

  test "technician has no permissions" do
    assert_not Permissions.has?("technician", Permissions::CREATE_INCIDENT)
    assert_not Permissions.has?("technician", Permissions::VIEW_PROPERTIES)
    assert_not Permissions.has?("technician", Permissions::MANAGE_USERS)
  end

  # --- Property Manager (PM) ---

  test "property_manager can create incidents and view properties" do
    assert Permissions.has?("property_manager", Permissions::CREATE_INCIDENT)
    assert Permissions.has?("property_manager", Permissions::VIEW_PROPERTIES)

    assert_not Permissions.has?("property_manager", Permissions::TRANSITION_STATUS)
    assert_not Permissions.has?("property_manager", Permissions::CREATE_PROPERTY)
    assert_not Permissions.has?("property_manager", Permissions::MANAGE_ORGANIZATIONS)
  end

  # --- Area Manager (PM) ---

  test "area_manager can create incidents and view properties" do
    assert Permissions.has?("area_manager", Permissions::CREATE_INCIDENT)
    assert Permissions.has?("area_manager", Permissions::VIEW_PROPERTIES)

    assert_not Permissions.has?("area_manager", Permissions::MANAGE_USERS)
  end

  # --- Other (PM) ---

  test "other can only view properties by default" do
    assert Permissions.has?("other", Permissions::VIEW_PROPERTIES)

    assert_not Permissions.has?("other", Permissions::CREATE_INCIDENT)
    assert_not Permissions.has?("other", Permissions::MANAGE_ORGANIZATIONS)
  end

  # --- Unknown role ---

  test "unknown role has no permissions" do
    assert_not Permissions.has?("unknown", Permissions::CREATE_INCIDENT)
    assert_equal [], Permissions.for_role("unknown")
  end

  # --- for_role ---

  test "for_role returns permission list for valid role" do
    perms = Permissions.for_role("manager")
    assert_includes perms, Permissions::CREATE_INCIDENT
    assert_includes perms, Permissions::MANAGE_ON_CALL
    assert_equal 12, perms.length
  end

  # --- User#can? integration ---

  test "user.can? reads from JSONB permissions column" do
    org = Organization.create!(name: "Perm Test Org", organization_type: "mitigation")
    manager = org.users.create!(
      first_name: "Test", last_name: "Mgr", email_address: "perm-test@example.com",
      user_type: "manager", password: "password123", timezone: "America/Chicago",
      permissions: Permissions.defaults_for("manager")
    )
    assert manager.can?(Permissions::TRANSITION_STATUS)
    assert_not manager.can?(:nonexistent_permission)
  end

  test "other user with custom permissions can create incidents" do
    org = Organization.create!(name: "Custom Perm Org", organization_type: "property_management")
    other = org.users.create!(
      first_name: "Custom", last_name: "User", email_address: "custom@example.com",
      user_type: "other", password: "password123", timezone: "America/Chicago",
      permissions: %w[view_properties create_incident]
    )
    assert other.can?(:create_incident)
    assert other.can?(:view_properties)
    assert_not other.can?(:manage_users)
  end

  test "defaults_for returns string permissions for a role" do
    defaults = Permissions.defaults_for("manager")
    assert_includes defaults, "create_incident"
    assert_includes defaults, "transition_status"
    assert defaults.all? { |p| p.is_a?(String) }
  end
end
