require "application_system_test_case"
require_relative "planned_system_test_support"

class TeamManagementAdditionalTest < ApplicationSystemTestCase
  include PlannedSystemTestSupport

  setup do
    @original_local = Rails.application.config.consider_all_requests_local
    Rails.application.config.consider_all_requests_local = false

    @mitigation = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @pm = Organization.create!(name: "Greystar", organization_type: "property_management")

    @property = Property.create!(
      name: "River Oaks",
      mitigation_org: @mitigation,
      property_management_org: @pm,
      street_address: "100 Main St",
      city: "Houston",
      state: "TX",
      zip: "77001",
      unit_count: 60
    )

    @manager = User.create!(organization: @mitigation, user_type: User::MANAGER,
      email_address: "manager@example.com", first_name: "Mia", last_name: "Manager", password: "password123")
    @tech = User.create!(organization: @mitigation, user_type: User::TECHNICIAN,
      email_address: "tech@example.com", first_name: "Tina", last_name: "Tech", password: "password123")
    @pm_user = User.create!(organization: @pm, user_type: User::PROPERTY_MANAGER,
      email_address: "pm@example.com", first_name: "Pam", last_name: "PM", password: "password123")
    @pm_manager = User.create!(organization: @pm, user_type: User::PM_MANAGER,
      email_address: "pmmgr@example.com", first_name: "Paul", last_name: "Manager", password: "password123")

    PropertyAssignment.create!(user: @pm_user, property: @property)

    @incident = Incident.create!(
      property: @property,
      created_by_user: @manager,
      status: "active",
      project_type: "emergency_response",
      damage_type: "flood",
      description: "Active incident for manage tab tests"
    )

    @manager_assignment = IncidentAssignment.create!(incident: @incident, user: @manager, assigned_by_user: @manager)
    @pm_assignment = IncidentAssignment.create!(incident: @incident, user: @pm_user, assigned_by_user: @manager)
    @tech_assignment = IncidentAssignment.create!(incident: @incident, user: @tech, assigned_by_user: @manager)
  end

  teardown do
    Rails.application.config.consider_all_requests_local = @original_local
  end

  test "manage tab assignment flows remain operable and scoped by role" do
    login_as @manager
    visit incident_path(@incident)
    open_manage_tab

    # Manager can operate Manage tab and sees assign controls.
    assert_selector "button", text: "Assign User"

    Capybara.reset_sessions!

    login_as @pm_user
    visit incident_path(@incident)
    open_manage_tab

    click_button "Assign User"
    assert_no_selector "[role='option']", text: "Tina Tech"
    assert_selector "[role='option']", text: "Paul Manager"
    find("[role='option']", text: "Paul Manager").click

    assert_text "Paul Manager"
    assert @incident.reload.assigned_users.include?(@pm_manager)
  end

  test "pm user cannot assign mitigation users via direct path" do
    login_as @pm_user
    visit incident_path(@incident)

    submit_assignment_create(@incident, @tech.id)

    assert_not_found_rendered
    assert_equal 1, IncidentAssignment.where(incident: @incident, user: @tech).count
  end

  test "manager removes user from incident" do
    login_as @manager
    visit incident_path(@incident)
    open_manage_tab

    # Remove the technician assignment via visible remove button and confirm dialog.
    find("button[title='Remove Tina Tech']").click

    within("[role='dialog']") do
      assert_text "Remove Team Member"
      click_button "Remove"
    end

    assert_no_selector "button[title='Remove Tina Tech']"
    assert_not IncidentAssignment.exists?(@tech_assignment.id)
  end

  test "pm user cannot remove mitigation user" do
    login_as @pm_user
    visit incident_path(@incident)

    submit_assignment_delete(@incident, @tech_assignment)

    assert_not_found_rendered
    assert IncidentAssignment.exists?(@tech_assignment.id)
  end

  test "manager assigns property user on property page" do
    login_as @manager
    visit property_path(@property)

    click_button "+ Assign"
    find("[role='combobox']").click
    find("[role='option']", text: "Paul Manager (PM Manager)").click
    click_button "Assign"

    assert_text "Paul Manager"
    assert PropertyAssignment.exists?(user: @pm_manager, property: @property)
  end

  test "manager removes property assignment" do
    assignment = PropertyAssignment.find_by!(user: @pm_user, property: @property)

    login_as @manager
    visit property_path(@property)

    within("section", text: "Assigned Users") do
      click_button "Remove", match: :first
    end

    within("[role='dialog']") do
      assert_text "Remove Assignment"
      click_button "Remove"
    end

    within("section", text: "Assigned Users") do
      assert_text "No users assigned to this property."
      assert_no_link "Pam PM"
    end
    assert_not PropertyAssignment.exists?(assignment.id)
  end

  private

  def open_manage_tab
    click_button "Manage"
    assert_text "Mitigation Team"
    assert_text "Property Management"
  end

  def submit_assignment_create(incident, user_id)
    submit_method_override_form(incident_assignments_path(incident), "post", { "user_id" => user_id.to_s })
  end

  def submit_assignment_delete(incident, assignment)
    submit_method_override_form(incident_assignment_path(incident, assignment), "delete", {})
  end

  def submit_method_override_form(path, verb, fields)
    js = <<~JS
      const [path, verb, fields] = arguments;
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
      if (verb !== 'post') addField('_method', verb);
      Object.entries(fields).forEach(([k, v]) => addField(k, String(v)));
      document.body.appendChild(form);
      form.submit();
    JS
    page.execute_script(js, path, verb, fields)
  end

  def assert_not_found_rendered
    production_404 = page.has_text?("The page you were looking for") && page.has_text?("exist")
    debug_404 = page.has_text?("ActiveRecord::RecordNotFound")
    assert(production_404 || debug_404, "Expected not-found response, got:\n#{page.text}")
  end
end
