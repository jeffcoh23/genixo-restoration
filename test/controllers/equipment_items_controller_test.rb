require "test_helper"

class EquipmentItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @org = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @pm_org = Organization.create!(name: "Greystar", organization_type: "property_management")
    @type = EquipmentType.create!(name: "Dehumidifier", organization: @org)

    @manager = User.create!(
      organization: @org, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager",
      password: "password123"
    )

    @pm_user = User.create!(
      organization: @pm_org, user_type: "property_manager",
      email_address: "pm@greystar.com", first_name: "PM", last_name: "User",
      password: "password123"
    )

    @item = EquipmentItem.create!(
      equipment_type: @type, organization: @org,
      identifier: "DH-001", equipment_model: "LGR 7000"
    )
  end

  # --- Authorization ---

  test "mitigation manager can access index" do
    login_as @manager
    get equipment_items_path
    assert_response :success
  end

  test "PM user cannot access index" do
    login_as @pm_user
    get equipment_items_path
    assert_response :not_found
  end

  # --- Create ---

  test "create adds new equipment item" do
    login_as @manager
    assert_difference "EquipmentItem.count", 1 do
      post equipment_items_path, params: {
        equipment_item: { equipment_type_id: @type.id, identifier: "DH-002", equipment_model: "LGR 8000" }
      }
    end
    assert_redirected_to equipment_items_path
  end

  test "create rejects missing identifier" do
    login_as @manager
    assert_no_difference "EquipmentItem.count" do
      post equipment_items_path, params: {
        equipment_item: { equipment_type_id: @type.id, identifier: "" }
      }
    end
    assert_redirected_to equipment_items_path
  end

  # --- Update ---

  test "update changes equipment item" do
    login_as @manager
    patch equipment_item_path(@item), params: {
      equipment_item: { equipment_model: "LGR 9000" }
    }
    assert_redirected_to equipment_items_path
    assert_equal "LGR 9000", @item.reload.equipment_model
  end

  test "update can deactivate item" do
    login_as @manager
    patch equipment_item_path(@item), params: {
      equipment_item: { active: false }
    }
    assert_redirected_to equipment_items_path
    assert_equal false, @item.reload.active
  end

  test "cannot update item from another org" do
    other_org = Organization.create!(name: "Other", organization_type: "mitigation")
    other_type = EquipmentType.create!(name: "Fan", organization: other_org)
    other_item = EquipmentItem.create!(equipment_type: other_type, organization: other_org, identifier: "FAN-001")

    login_as @manager
    patch equipment_item_path(other_item), params: {
      equipment_item: { equipment_model: "Hacked" }
    }
    assert_response :not_found
  end

  private

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end
end
