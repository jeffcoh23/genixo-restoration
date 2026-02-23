require "application_system_test_case"
require_relative "planned_system_test_support"

class SecurityAdditionalTest < ApplicationSystemTestCase
  include PlannedSystemTestSupport

  setup do
    @original_local = Rails.application.config.consider_all_requests_local
    Rails.application.config.consider_all_requests_local = false

    @mitigation = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @pm = Organization.create!(name: "Greystar", organization_type: "property_management")

    @property = Property.create!(name: "River Oaks", mitigation_org: @mitigation, property_management_org: @pm)

    @manager = User.create!(organization: @mitigation, user_type: User::MANAGER,
      email_address: "manager@example.com", first_name: "Mia", last_name: "Manager", password: "password123")
    @tech = User.create!(organization: @mitigation, user_type: User::TECHNICIAN,
      email_address: "tech@example.com", first_name: "Tina", last_name: "Tech", password: "password123")
    @pm_user = User.create!(organization: @pm, user_type: User::PROPERTY_MANAGER,
      email_address: "pm@example.com", first_name: "Pam", last_name: "PM", password: "password123")
    @pm_manager = User.create!(organization: @pm, user_type: User::PM_MANAGER,
      email_address: "pmmgr@example.com", first_name: "Paul", last_name: "Manager", password: "password123")
  end

  teardown do
    Rails.application.config.consider_all_requests_local = @original_local
  end

  test "cross org equipment isolation blocks patching equipment item" do
    org_a = @mitigation
    org_b = Organization.create!(name: "Other Mitigation", organization_type: "mitigation")

    own_type = EquipmentType.create!(organization: org_a, name: "Air Mover")
    EquipmentItem.create!(organization: org_a, equipment_type: own_type, identifier: "AM-001")

    other_type = EquipmentType.create!(organization: org_b, name: "Dehumidifier")
    other_item = EquipmentItem.create!(organization: org_b, equipment_type: other_type, identifier: "DH-999")

    login_as @manager
    visit equipment_items_path
    assert_text "AM-001"
    assert_no_text "DH-999"

    submit_cross_org_equipment_patch(other_item, other_type)

    assert_not_found_rendered
    assert_equal "DH-999", other_item.reload.identifier
  end

  test "technician cannot create incident" do
    login_as @tech
    visit new_incident_path
    assert_not_found_rendered
  end

  test "pm manager cannot create incident" do
    login_as @pm_manager
    visit new_incident_path
    assert_not_found_rendered
  end

  test "non manager blocked from on call settings" do
    login_as @tech
    visit on_call_settings_path
    assert_not_found_rendered

    Capybara.reset_sessions!
    login_as @pm_user
    visit on_call_settings_path
    assert_not_found_rendered
  end

  test "non manager blocked from equipment inventory" do
    login_as @tech
    visit equipment_items_path
    assert_not_found_rendered

    Capybara.reset_sessions!
    login_as @pm_user
    visit equipment_items_path
    assert_not_found_rendered
  end

  test "non manager blocked from organizations index" do
    login_as @tech
    visit organizations_path
    assert_not_found_rendered

    Capybara.reset_sessions!
    login_as @pm_user
    visit organizations_path
    assert_not_found_rendered
  end

  test "non manager blocked from user management index" do
    login_as @tech
    visit users_path
    assert_not_found_rendered

    Capybara.reset_sessions!
    login_as @pm_user
    visit users_path
    assert_not_found_rendered
  end

  test "authenticated user redirected away from login" do
    login_as @manager
    visit login_path

    assert_text "Mia Manager" # wait for redirect/render
    assert_current_path incidents_path
    assert_no_field "email_address"
  end

  test "emergency visual indicators render on incident list" do
    emergency_incident = Incident.create!(
      property: @property,
      created_by_user: @manager,
      status: "acknowledged",
      emergency: true,
      project_type: "emergency_response",
      damage_type: "flood",
      description: "Emergency water extraction"
    )
    standard_incident = Incident.create!(
      property: @property,
      created_by_user: @manager,
      status: "acknowledged",
      emergency: false,
      project_type: "emergency_response",
      damage_type: "flood",
      description: "Standard acknowledged issue"
    )

    login_as @manager
    visit incidents_path

    within(find("tr", text: emergency_incident.description)) do
      assert_text "Emergency"
      assert_no_text "Acknowledged"
    end

    within(find("tr", text: standard_incident.description)) do
      assert_text "Acknowledged"
    end
  end

  test "incidents pagination preserves filters in url and reload" do
    27.times do |i|
      Incident.create!(
        property: @property,
        created_by_user: @manager,
        status: "active",
        project_type: "emergency_response",
        damage_type: "flood",
        description: "Filtered active incident #{i}"
      )
    end
    Incident.create!(
      property: @property,
      created_by_user: @manager,
      status: "on_hold",
      project_type: "emergency_response",
      damage_type: "flood",
      description: "Should be filtered out"
    )

    login_as @manager
    visit incidents_path(status: "active")

    assert_text "Page 1 of"
    find("[data-testid='incidents-pagination-next']").click

    assert_text "Page 2 of"
    assert_match(/status=active/, page.current_url)
    assert_match(/page=2/, page.current_url)
    assert_no_text "Should be filtered out"

    visit page.current_url
    assert_match(/status=active/, page.current_url)
    assert_match(/page=2/, page.current_url)
    assert_no_text "Should be filtered out"
  end

  test "technician labor post with another user id is forced to self" do
    incident = Incident.create!(
      property: @property,
      created_by_user: @manager,
      status: "active",
      project_type: "emergency_response",
      damage_type: "flood",
      description: "Labor authorization test"
    )
    IncidentAssignment.create!(incident: incident, user: @tech, assigned_by_user: @manager)

    login_as @tech
    visit incident_path(incident)

    submit_labor_entry_form(
      incident: incident,
      user_id: @manager.id,
      role_label: "Technician",
      started_at: "#{Date.current}T08:00",
      ended_at: "#{Date.current}T10:00"
    )

    assert_text "Labor entry created."
    entry = incident.labor_entries.order(:id).last
    assert_equal @tech.id, entry.user_id
    assert_equal @tech.id, entry.created_by_user_id
  end

  test "invitation targeting only allows serviced property management orgs" do
    serviced_pm = @pm
    unserviced_pm = Organization.create!(name: "Unserviced PM", organization_type: "property_management")
    Property.create!(name: "Serviceable Site", mitigation_org: @mitigation, property_management_org: serviced_pm)

    login_as @manager
    visit users_path

    click_button "Invite User"
    within("[role='dialog']") do
      all("[role='combobox']").first.click
    end
    assert_text serviced_pm.name
    assert_no_text unserviced_pm.name
    send_keys :escape

    submit_invitation_form(org_id: unserviced_pm.id, email: "blocked@example.com", user_type: User::PROPERTY_MANAGER)
    assert_not_found_rendered
    assert_nil Invitation.find_by(email: "blocked@example.com")
  end

  SECURITY_CASES = {
    # Filled
  }.freeze

  SECURITY_CASES.each do |id, description|
    test description do
      pending_e2e id, "Security/system coverage backlog; prefer stable route and selector assertions over copy-only checks"
    end
  end

  private

  def submit_cross_org_equipment_patch(item, equipment_type)
    js = <<~JS
      const path = arguments[0];
      const typeId = String(arguments[1]);
      const token = document.querySelector('meta[name="csrf-token"]')?.content;
      const form = document.createElement('form');
      form.method = 'POST';
      form.action = path;
      const addField = (name, value) => {
        const input = document.createElement('input');
        input.type = 'hidden';
        input.name = name;
        input.value = value;
        form.appendChild(input);
      };
      addField('_method', 'patch');
      if (token) addField('authenticity_token', token);
      addField('equipment_item[identifier]', 'HACK-ATTEMPT');
      addField('equipment_item[equipment_type_id]', typeId);
      document.body.appendChild(form);
      form.submit();
    JS

    page.execute_script(js, equipment_item_path(item), equipment_type.id)
  end

  def submit_labor_entry_form(incident:, user_id:, role_label:, started_at:, ended_at:)
    js = <<~JS
      const [path, userId, roleLabel, startedAt, endedAt] = arguments;
      const token = document.querySelector('meta[name="csrf-token"]')?.content;
      const form = document.createElement('form');
      form.method = 'POST';
      form.action = path;
      const addField = (name, value) => {
        const input = document.createElement('input');
        input.type = 'hidden';
        input.name = name;
        input.value = value;
        form.appendChild(input);
      };
      if (token) addField('authenticity_token', token);
      addField('labor_entry[user_id]', String(userId));
      addField('labor_entry[role_label]', roleLabel);
      addField('labor_entry[log_date]', startedAt.slice(0, 10));
      addField('labor_entry[started_at]', startedAt);
      addField('labor_entry[ended_at]', endedAt);
      document.body.appendChild(form);
      form.submit();
    JS
    page.execute_script(js, incident_labor_entries_path(incident), user_id, role_label, started_at, ended_at)
  end

  def submit_invitation_form(org_id:, email:, user_type:)
    js = <<~JS
      const [path, orgId, email, userType] = arguments;
      const token = document.querySelector('meta[name="csrf-token"]')?.content;
      const form = document.createElement('form');
      form.method = 'POST';
      form.action = path;
      const addField = (name, value) => {
        const input = document.createElement('input');
        input.type = 'hidden';
        input.name = name;
        input.value = value;
        form.appendChild(input);
      };
      if (token) addField('authenticity_token', token);
      addField('organization_id', String(orgId));
      addField('email', email);
      addField('user_type', userType);
      addField('first_name', 'Blocked');
      addField('last_name', 'Invite');
      document.body.appendChild(form);
      form.submit();
    JS
    page.execute_script(js, invitations_path, org_id, email, user_type)
  end

  def assert_not_found_rendered
    production_404 = page.has_text?("The page you were looking for") && page.has_text?("exist")
    debug_404 = page.has_text?("ActiveRecord::RecordNotFound")

    assert(production_404 || debug_404, "Expected not-found response, got:\n#{page.text}")
  end
end
