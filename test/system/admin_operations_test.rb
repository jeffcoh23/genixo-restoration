require "application_system_test_case"
require_relative "planned_system_test_support"

class AdminOperationsTest < ApplicationSystemTestCase
  include PlannedSystemTestSupport

  setup do
    @mitigation = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @pm = Organization.create!(name: "Greystar", organization_type: "property_management")
    @manager = User.create!(organization: @mitigation, user_type: User::MANAGER,
      email_address: "manager@example.com", first_name: "Mia", last_name: "Manager", password: "password123")
  end

  test "create property management organization" do
    login_as @manager
    visit organizations_path

    click_link "New Company"
    fill_in "Name", with: "Sandalwood Management"
    fill_in "Phone", with: "713-555-2222"
    fill_in "Email", with: "info@sandalwood.com"
    fill_in "Street Address", with: "100 Main St"
    fill_in "City", with: "Houston"
    fill_in "State", with: "TX"
    fill_in "Zip", with: "77002"
    click_button "Create Company"

    assert_text "Organization created."
    assert_text "Sandalwood Management"

    org = Organization.find_by!(name: "Sandalwood Management")
    assert_equal "property_management", org.organization_type
  end

  test "create property" do
    login_as @manager
    visit properties_path

    click_link "New Property"
    fill_in "Name", with: "Park at River Oaks"
    fill_in "Street Address", with: "200 Oak Dr"
    fill_in "City", with: "Houston"
    fill_in "State", with: "TX"
    fill_in "Zip", with: "77003"
    fill_in "Unit Count", with: "120"

    find("[role='combobox']").click
    find("[role='option']", text: "Greystar").click

    click_button "Create Property"

    assert_text "Property created."
    assert_text "Park at River Oaks"

    property = Property.find_by!(name: "Park at River Oaks")
    assert_equal @mitigation.id, property.mitigation_org_id
    assert_equal @pm.id, property.property_management_org_id
  end

  test "invite user in own org" do
    # Include a serviced PM org to ensure the organization picker is present and role scoping works.
    Property.create!(name: "River Oaks", mitigation_org: @mitigation, property_management_org: @pm)

    login_as @manager
    visit users_path

    click_button "Invite User"
    within("[role='dialog']") do
      fill_in "Email", with: "newtech@example.com"

      all("[role='combobox']")[0].click
    end
    find("[role='option']", text: "Genixo").click

    within("[role='dialog']") do
      all("[role='combobox']")[1].click
    end
    find("[role='option']", text: "Technician").click

    within("[role='dialog']") do
      fill_in "First Name", with: "Nina"
      fill_in "Last Name", with: "New"
      click_button "Send Invitation"
    end

    assert_text "Invitation sent to newtech@example.com."
    assert_text "Pending Invitations (1)"
    assert_text "newtech@example.com"

    invitation = Invitation.find_by!(email: "newtech@example.com")
    assert_equal @mitigation.id, invitation.organization_id
    assert_equal User::TECHNICIAN, invitation.user_type
  end

  test "deactivate user" do
    user = User.create!(organization: @mitigation, user_type: User::TECHNICIAN,
      email_address: "deactivate@example.com", first_name: "Dana", last_name: "Deactivate", password: "password123")

    login_as @manager
    visit user_path(user)

    click_button "Deactivate"
    within("[role='dialog']") do
      assert_text "Deactivate User"
      click_button "Deactivate"
    end

    assert_text "has been deactivated"
    assert_text "Deactivated"
    assert_button "Reactivate"
    assert_equal false, user.reload.active
  end

  test "edit property management organization" do
    login_as @manager
    visit organization_path(@pm)

    click_link "Edit"
    fill_in "Phone", with: "713-555-8899"
    fill_in "Email", with: "regional@greystar.com"
    fill_in "Street Address", with: "500 Post Oak Blvd"
    click_button "Save Changes"

    assert_text "Organization updated."
    assert_text "regional@greystar.com"

    @pm.reload
    assert_equal "713-555-8899", @pm.phone
    assert_equal "regional@greystar.com", @pm.email
    assert_equal "500 Post Oak Blvd", @pm.street_address
  end

  test "mitigation admin edits property and can change pm org" do
    other_pm = Organization.create!(name: "Sandalwood", organization_type: "property_management")
    property = Property.create!(name: "River Oaks", mitigation_org: @mitigation, property_management_org: @pm)

    login_as @manager
    visit edit_property_path(property)

    assert_text "Edit Property"
    assert_text "PM Organization"

    find("#pm_org").click
    find("[role='option']", text: "Sandalwood").click
    fill_in "Unit Count", with: "250"
    click_button "Save Changes"

    assert_text "Property updated."
    assert_text "Sandalwood"

    property.reload
    assert_equal other_pm.id, property.property_management_org_id
    assert_equal 250, property.unit_count
  end

  test "pm user editing property cannot change org" do
    other_pm = Organization.create!(name: "Sandalwood", organization_type: "property_management")
    property = Property.create!(name: "River Oaks", mitigation_org: @mitigation, property_management_org: @pm, unit_count: 120)
    pm_user = User.create!(organization: @pm, user_type: User::PROPERTY_MANAGER,
      email_address: "amy@example.com", first_name: "Amy", last_name: "Chen", password: "password123")
    PropertyAssignment.create!(property: property, user: pm_user)

    login_as pm_user
    visit edit_property_path(property)

    assert_no_text "PM Organization *"
    assert_no_selector "#pm_org"
    fill_in "Unit Count", with: "135"
    click_button "Save Changes"

    assert_text "Property updated."
    property.reload
    assert_equal 135, property.unit_count
    assert_equal @pm.id, property.property_management_org_id
  end

  test "invite user to serviced property management org" do
    Property.create!(name: "River Oaks", mitigation_org: @mitigation, property_management_org: @pm)

    login_as @manager
    visit users_path

    click_button "Invite User"
    within("[role='dialog']") do
      fill_in "Email", with: "pminvite@example.com"
      all("[role='combobox']")[0].click
    end
    find("[role='option']", text: "Greystar").click

    within("[role='dialog']") do
      all("[role='combobox']")[1].click
    end
    find("[role='option']", text: "Property Manager").click

    within("[role='dialog']") do
      fill_in "First Name", with: "Paula"
      fill_in "Last Name", with: "Manager"
      click_button "Send Invitation"
    end

    assert_text "Invitation sent to pminvite@example.com."
    invitation = Invitation.find_by!(email: "pminvite@example.com")
    assert_equal @pm.id, invitation.organization_id
    assert_equal User::PROPERTY_MANAGER, invitation.user_type
  end

  test "resend invitation" do
    invitation = Invitation.create!(
      organization: @mitigation,
      invited_by_user: @manager,
      email: "pending@example.com",
      user_type: User::TECHNICIAN,
      token: "old-token",
      expires_at: 2.days.from_now
    )
    original_token = invitation.token
    original_expires_at = invitation.expires_at

    login_as @manager
    visit users_path

    row = find("tr", text: invitation.email)
    within(row) { click_button "Resend" }

    assert_text "Invitation resent to pending@example.com."
    invitation.reload
    assert_not_equal original_token, invitation.token
    assert_operator invitation.expires_at, :>, original_expires_at
  end

  test "manager cannot deactivate self" do
    login_as @manager
    visit user_path(@manager)

    assert_no_button "Deactivate"
    assert_no_button "Reactivate"
  end

  test "reactivate user" do
    user = User.create!(organization: @mitigation, user_type: User::TECHNICIAN,
      email_address: "reactivate@example.com", first_name: "Rhea", last_name: "Reactivate", password: "password123", active: false)

    login_as @manager
    visit user_path(user)

    assert_button "Reactivate"
    click_button "Reactivate"

    assert_text "has been reactivated"
    assert_no_text "Deactivated"
    assert_equal true, user.reload.active
  end

  test "add equipment item" do
    type = EquipmentType.create!(organization: @mitigation, name: "Dehumidifier")

    login_as @manager
    visit equipment_items_path

    click_button "Add Item"
    within("[role='dialog']") do
      find("[role='combobox']").click
    end
    find("[role='option']", text: type.name).click

    within("[role='dialog']") do
      fill_in "e.g. DH-042", with: "DH-042"
      fill_in "e.g. LGR 7000XLi", with: "LGR 7000XLi"
      click_button "Add Item"
    end

    assert_text "DH-042 added."
    assert_text "DH-042"
    item = EquipmentItem.find_by!(identifier: "DH-042")
    assert_equal type.id, item.equipment_type_id
    assert_equal "LGR 7000XLi", item.equipment_model
  end

  test "edit equipment item inline" do
    type = EquipmentType.create!(organization: @mitigation, name: "Dehumidifier")
    other_type = EquipmentType.create!(organization: @mitigation, name: "Air Mover")
    item = EquipmentItem.create!(organization: @mitigation, equipment_type: type, identifier: "DH-001", equipment_model: "Old Model")

    login_as @manager
    visit equipment_items_path

    find("[data-testid='equipment-item-edit-#{item.id}']").click
    row = find("[data-testid='equipment-item-row-#{item.id}']")
    within(row) do
      all("input")[0].set("AM-001")
      all("[role='combobox']").first.click
    end
    find("[role='option']", text: other_type.name).click
    row = find("[data-testid='equipment-item-row-#{item.id}']")
    within(row) do
      inputs = all("input")
      inputs.last.set("Axial 2000")
      click_button "Save"
    end

    assert_text "AM-001 updated."
    item.reload
    assert_equal "AM-001", item.identifier
    assert_equal other_type.id, item.equipment_type_id
    assert_equal "Axial 2000", item.equipment_model
  end

  test "deactivate equipment item" do
    type = EquipmentType.create!(organization: @mitigation, name: "Dehumidifier")
    item = EquipmentItem.create!(organization: @mitigation, equipment_type: type, identifier: "DH-999")

    login_as @manager
    visit equipment_items_path

    find("[data-testid='equipment-item-deactivate-#{item.id}']").click

    assert_text "DH-999 updated."
    assert_nil EquipmentItem.find_by(id: item.id, active: true)
    assert_no_selector "[data-testid='equipment-item-row-#{item.id}']"
  end

  test "add equipment type" do
    login_as @manager
    visit equipment_items_path

    find("[data-testid='equipment-manage-types']").click
    click_button "Add Type"

    within(all("[role='dialog']").find { |d| d.has_text?("Add Equipment Type") }) do
      fill_in "e.g. Dehumidifier", with: "Air Scrubber"
      click_button "Add Type"
    end

    assert_text "Equipment type added."
    assert_text "Air Scrubber"
    assert EquipmentType.exists?(organization: @mitigation, name: "Air Scrubber", active: true)
  end

  test "deactivate equipment type" do
    type = EquipmentType.create!(organization: @mitigation, name: "Dehumidifier")

    login_as @manager
    visit equipment_items_path
    find("[data-testid='equipment-manage-types']").click

    find("[data-testid='equipment-type-deactivate-#{type.id}']").click

    assert_text "Dehumidifier deactivated."
    assert_equal false, type.reload.active
  end

  test "reactivate equipment type" do
    type = EquipmentType.create!(organization: @mitigation, name: "Dehumidifier", active: false)

    login_as @manager
    visit equipment_items_path
    find("[data-testid='equipment-manage-types']").click

    find("[data-testid='equipment-type-reactivate-#{type.id}']").click

    assert_text "Dehumidifier reactivated."
    assert_equal true, type.reload.active
  end

  test "view equipment placement history" do
    type = EquipmentType.create!(organization: @mitigation, name: "Dehumidifier")
    item = EquipmentItem.create!(organization: @mitigation, equipment_type: type, identifier: "DH-200", equipment_model: "LGR 7000XLi")
    property = Property.create!(name: "River Oaks", mitigation_org: @mitigation, property_management_org: @pm)
    incident = Incident.create!(property: property, created_by_user: @manager,
      status: "active", project_type: "emergency_response", damage_type: "flood", description: "Placement history test")
    EquipmentEntry.create!(
      incident: incident,
      logged_by_user: @manager,
      equipment_item: item,
      equipment_type: type,
      equipment_identifier: item.identifier,
      equipment_model: item.equipment_model,
      placed_at: Date.current,
      location_notes: "Unit 201 bedroom"
    )

    login_as @manager
    visit equipment_items_path
    find("[data-testid='equipment-item-history-#{item.id}']").click

    assert_text "PLACEMENT HISTORY"
    assert_text "River Oaks"
    assert_text "Unit 201 bedroom"
    assert_text "ACTIVE"
  end

  test "configure on-call primary and timeout" do
    other_manager = User.create!(organization: @mitigation, user_type: User::OFFICE_SALES,
      email_address: "ops@example.com", first_name: "Omar", last_name: "Ops", password: "password123")
    config = OnCallConfiguration.create!(organization: @mitigation, primary_user: @manager, escalation_timeout_minutes: 10)

    login_as @manager
    visit on_call_settings_path

    find("[data-testid='oncall-primary-select']").click
    find("[role='option']", text: /Omar Ops/).click
    find("[data-testid='oncall-timeout']").set("15")
    find("[data-testid='oncall-save-config']").click

    assert_text "On-call configuration saved."
    config.reload
    assert_equal other_manager.id, config.primary_user_id
    assert_equal 15, config.escalation_timeout_minutes
  end

  test "add escalation contact" do
    primary = @manager
    secondary = User.create!(organization: @mitigation, user_type: User::MANAGER,
      email_address: "second@example.com", first_name: "Sam", last_name: "Second", password: "password123")
    config = OnCallConfiguration.create!(organization: @mitigation, primary_user: primary, escalation_timeout_minutes: 10)

    login_as @manager
    visit on_call_settings_path

    find("[data-testid='escalation-add-select']").click
    find("[role='option']", text: /Sam Second/).click
    find("[data-testid='escalation-add-button']").click

    assert_text "Escalation contact added."
    contact = config.escalation_contacts.order(:position).last
    assert_equal secondary.id, contact.user_id
    assert_equal 1, contact.position
  end

  test "reorder escalation chain" do
    primary = @manager
    u1 = User.create!(organization: @mitigation, user_type: User::MANAGER,
      email_address: "one@example.com", first_name: "Alpha", last_name: "One", password: "password123")
    u2 = User.create!(organization: @mitigation, user_type: User::MANAGER,
      email_address: "two@example.com", first_name: "Bravo", last_name: "Two", password: "password123")
    config = OnCallConfiguration.create!(organization: @mitigation, primary_user: primary, escalation_timeout_minutes: 10)
    c1 = EscalationContact.create!(on_call_configuration: config, user: u1, position: 1)
    c2 = EscalationContact.create!(on_call_configuration: config, user: u2, position: 2)

    login_as @manager
    visit on_call_settings_path

    find("[data-testid='escalation-contact-down-#{c1.id}']").click

    assert_text "Escalation order updated."
    ordered_ids = config.escalation_contacts.order(:position).pluck(:id)
    assert_equal [ c2.id, c1.id ], ordered_ids
  end

  test "remove escalation contact" do
    primary = @manager
    u1 = User.create!(organization: @mitigation, user_type: User::MANAGER,
      email_address: "remove-chain@example.com", first_name: "Rex", last_name: "Chain", password: "password123")
    config = OnCallConfiguration.create!(organization: @mitigation, primary_user: primary, escalation_timeout_minutes: 10)
    contact = EscalationContact.create!(on_call_configuration: config, user: u1, position: 1)

    login_as @manager
    visit on_call_settings_path

    find("[data-testid='escalation-contact-remove-#{contact.id}']").click

    assert_text "Escalation contact removed."
    assert_nil EscalationContact.find_by(id: contact.id)
  end

  ADMIN_CASES = {
    # Filled
  }.freeze

  ADMIN_CASES.each do |id, description|
    test description do
      pending_e2e id, "Admin E2E backlog; selectors and workflows need stabilization after UI cleanup"
    end
  end
end
