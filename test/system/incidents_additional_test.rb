require "application_system_test_case"
require_relative "planned_system_test_support"

class IncidentsAdditionalTest < ApplicationSystemTestCase
  include PlannedSystemTestSupport

  setup do
    @mitigation = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @pm = Organization.create!(name: "Greystar", organization_type: "property_management")
    @other_pm = Organization.create!(name: "Sandalwood", organization_type: "property_management")

    @property_a = Property.create!(name: "River Oaks", mitigation_org: @mitigation, property_management_org: @pm)
    @property_b = Property.create!(name: "Sandalwood Towers", mitigation_org: @mitigation, property_management_org: @other_pm)

    @manager = User.create!(organization: @mitigation, user_type: User::MANAGER,
      email_address: "manager@example.com", first_name: "Mia", last_name: "Manager", password: "password123")
    @actor = User.create!(organization: @mitigation, user_type: User::TECHNICIAN,
      email_address: "actor@example.com", first_name: "Alex", last_name: "Actor", password: "password123")

    @active_incident = Incident.create!(property: @property_a, created_by_user: @manager,
      status: "active", project_type: "emergency_response", damage_type: "flood",
      description: "Kitchen flood in unit 101")
    @proposal_incident = Incident.create!(property: @property_a, created_by_user: @manager,
      status: "proposal_requested", project_type: "mitigation_rfq", damage_type: "mold",
      description: "Mold quote requested for hallway")
    @other_property_incident = Incident.create!(property: @property_b, created_by_user: @manager,
      status: "on_hold", project_type: "buildback_rfq", damage_type: "fire",
      description: "Fire rebuild paused pending approval")
  end

  test "incidents index filters by status" do
    login_as @manager
    visit incidents_path

    click_button "All Statuses"
    find("[role='option']", text: "Active").click

    assert_text "Kitchen flood in unit 101"
    assert_no_text "Mold quote requested for hallway"
    assert_no_text "Fire rebuild paused pending approval"
    assert_match(/status=active/, page.current_url)
  end

  test "incidents index filters by property" do
    login_as @manager
    visit incidents_path

    click_button "All Properties"
    find("[role='option']", text: "River Oaks").click

    assert_text "Kitchen flood in unit 101"
    assert_text "Mold quote requested for hallway"
    assert_no_text "Fire rebuild paused pending approval"
    assert_match(/property_id=/, page.current_url)
  end

  test "incidents index search matches description or property" do
    login_as @manager
    visit incidents_path

    fill_in "Search incidents...", with: "hallway"
    find("button[aria-label='Run search']").click

    assert_text "Mold quote requested for hallway"
    assert_no_text "Kitchen flood in unit 101"

    fill_in "Search incidents...", with: "Sandalwood"
    find("button[aria-label='Run search']").click

    assert_text "Fire rebuild paused pending approval"
    assert_no_text "Kitchen flood in unit 101"
  end

  test "incidents index sort toggles column direction" do
    login_as @manager
    visit incidents_path(sort: "property", direction: "asc")
    assert_equal [ "River Oaks", "River Oaks", "Sandalwood Towers" ], visible_property_names

    visit incidents_path(sort: "property", direction: "desc")
    assert_equal [ "Sandalwood Towers", "River Oaks", "River Oaks" ], visible_property_names
  end

  test "incidents index pagination navigates page 2" do
    27.times do |i|
      Incident.create!(
        property: @property_a,
        created_by_user: @manager,
        status: "active",
        project_type: "emergency_response",
        damage_type: "flood",
        description: "Bulk seeded incident #{i}"
      )
    end

    login_as @manager
    visit incidents_path

    assert_text "Page 1 of"
    pagination_buttons = all("button", minimum: 2).select { |b| b[:class].to_s.include?("h-10") || b[:class].to_s.include?("h-8") }
    pagination_buttons.last.click

    assert_text "Page 2 of"
    assert_match(/[?&]page=2/, page.current_url)
  end

  test "incident detail overview shows key fields" do
    incident = Incident.create!(
      property: @property_a,
      created_by_user: @manager,
      status: "acknowledged",
      project_type: "emergency_response",
      damage_type: "fire",
      description: "Laundry room fire response",
      cause: "Dryer vent issue",
      requested_next_steps: "Mitigate smoke odor"
    )

    login_as @manager
    visit incident_path(incident)

    assert_text "River Oaks"
    assert_text "Laundry room fire response"
    assert_text "Dryer vent issue"
    assert_text "Mitigate smoke odor"
    assert_text "Fire"
    assert_text "Emergency Response"
  end

  test "manager edits incident" do
    login_as @manager
    visit incident_path(@active_incident)

    click_button "Edit"
    within("[role='dialog']") do
      fill_in "edit_description", with: "Kitchen flood in unit 101 and 102"
      click_button "Save Changes"
    end

    assert_text "Incident updated."
    assert_text "Kitchen flood in unit 101 and 102"
    assert_equal "Kitchen flood in unit 101 and 102", @active_incident.reload.description
  end

  test "manager creates mitigation rfq incident" do
    login_as @manager
    visit new_incident_path

    select_new_incident_org_and_property("Greystar", "River Oaks")

    find("label", text: "Mitigation RFQ").click
    open_radix_select("Damage Type")
    click_radix_option("Mold")
    fill_in "description", with: "Quote requested for hallway mold remediation"

    incident = nil
    assert_difference -> { Incident.count }, +1 do
      click_button "Create Request"
      assert_text "Incident created."
      incident = Incident.order(:id).last
    end
    assert_equal "proposal_requested", incident.status
    assert_text "Quote requested for hallway mold remediation"
    assert_text "Proposal Requested"
  end

  test "incident create shows validation errors" do
    login_as @manager
    visit new_incident_path

    click_button "Create Request"

    assert_text "Property not found."
    assert_current_path new_incident_path
  end

  test "incident create respects team assignment selections" do
    office = User.create!(organization: @mitigation, user_type: User::OFFICE_SALES,
      email_address: "office@example.com", first_name: "Olive", last_name: "Office", password: "password123")
    tech = User.create!(organization: @mitigation, user_type: User::TECHNICIAN,
      email_address: "tech2@example.com", first_name: "Toby", last_name: "Tech", password: "password123")
    pm_mgr = User.create!(organization: @pm, user_type: User::PM_MANAGER,
      email_address: "pmmgr@example.com", first_name: "Paula", last_name: "Manager", password: "password123")
    pm_prop = User.create!(organization: @pm, user_type: User::PROPERTY_MANAGER,
      email_address: "pmprop@example.com", first_name: "Piper", last_name: "Property", password: "password123")
    PropertyAssignment.create!(property: @property_a, user: pm_prop)

    login_as @manager
    visit new_incident_path

    select_new_incident_org_and_property("Greystar", "River Oaks")

    find("label", text: "Emergency Response").click
    open_radix_select("Damage Type")
    click_radix_option("Flood")
    fill_in "description", with: "Team assignment selection test"

    assert_selector "[data-testid='new-incident-selected-count']", text: "4 members selected"
    office_checkbox = find("[data-testid='new-incident-assign-checkbox-#{office.id}']")
    tech_checkbox = find("[data-testid='new-incident-assign-checkbox-#{tech.id}']")
    assert_equal "checked", office_checkbox["data-state"]
    assert_equal "unchecked", tech_checkbox["data-state"]

    # Office is auto-assigned; mitigation technician is not. Toggle to validate user-driven selection changes.
    office_checkbox.click
    assert_selector "[data-testid='new-incident-selected-count']", text: "3 members selected"
    assert_equal "unchecked", find("[data-testid='new-incident-assign-checkbox-#{office.id}']")["data-state"]

    tech_checkbox = find("[data-testid='new-incident-assign-checkbox-#{tech.id}']")
    tech_checkbox.click
    assert_selector "[data-testid='new-incident-selected-count']", text: "4 members selected"
    assert_equal "checked", find("[data-testid='new-incident-assign-checkbox-#{tech.id}']")["data-state"]

    incident = nil
    assert_difference -> { Incident.count }, +1 do
      click_button "Create Request"
      assert_text "Incident created."
      incident = Incident.order(:id).last
    end
    assigned_ids = incident.assigned_user_ids
    assert_includes assigned_ids, @manager.id
    assert_includes assigned_ids, pm_mgr.id
    assert_includes assigned_ids, pm_prop.id
    assert_includes assigned_ids, tech.id
    assert_not_includes assigned_ids, office.id
  end

  test "incident create persists contacts" do
    login_as @manager
    visit new_incident_path

    select_new_incident_org_and_property("Greystar", "River Oaks")

    find("label", text: "Emergency Response").click
    open_radix_select("Damage Type")
    click_radix_option("Flood")
    fill_in "description", with: "Incident with contacts"

    click_button "Add Contact"
    contact_row = find("[data-testid='new-incident-contact-row-0']")
    within(contact_row) do
      find("input[placeholder='Name *']").fill_in with: "Jane Contact"
      find("input[placeholder='Title']").fill_in with: "Property Manager"
      find("input[placeholder='Email']").fill_in with: "jane@example.com"
      find("input[placeholder='Phone']").fill_in with: "713-555-0101"
      find("label", text: "Onsite contact").click
    end

    incident = nil
    assert_difference -> { Incident.count }, +1 do
      click_button "Create Request"
      assert_text "Incident created."
      incident = Incident.order(:id).last
    end

    find("[data-testid='incident-tab-manage']").click

    contact = incident.incident_contacts.find_by!(name: "Jane Contact")
    assert_equal true, contact.onsite
    assert_text "Jane Contact"
    assert_text "Property Manager"
    assert_text "jane@example.com"
  end

  test "technician cannot edit incident" do
    IncidentAssignment.create!(incident: @active_incident, user: @actor, assigned_by_user: @manager)

    login_as @actor
    visit incident_path(@active_incident)

    assert_no_button "Edit"

    submit_incident_patch(@active_incident, description: "Tampered edit")
    assert_not_found_rendered
    assert_equal "Kitchen flood in unit 101", @active_incident.reload.description
  end

  test "invalid status transition is rejected" do
    incident = Incident.create!(
      property: @property_a,
      created_by_user: @manager,
      status: "acknowledged",
      project_type: "emergency_response",
      damage_type: "flood",
      description: "Transition invalidation test",
      emergency: true
    )

    login_as @manager
    visit incident_path(incident)

    submit_transition_patch(incident, "proposal_submitted")

    assert_text "Cannot transition"
    assert_equal "acknowledged", incident.reload.status
  end

  test "non manager blocked from status transition endpoint" do
    incident = Incident.create!(
      property: @property_a,
      created_by_user: @manager,
      status: "acknowledged",
      project_type: "emergency_response",
      damage_type: "flood",
      description: "Transition auth test",
      emergency: true
    )
    IncidentAssignment.create!(incident: incident, user: @actor, assigned_by_user: @manager)

    login_as @actor
    visit incident_path(incident)
    submit_transition_patch(incident, "active")

    assert_not_found_rendered
    assert_equal "acknowledged", incident.reload.status
  end

  test "status transition resolves escalation" do
    incident = Incident.create!(
      property: @property_a,
      created_by_user: @manager,
      status: "acknowledged",
      project_type: "emergency_response",
      damage_type: "flood",
      description: "Escalation resolution test",
      emergency: true
    )
    escalation = EscalationEvent.create!(
      incident: incident,
      user: @manager,
      contact_method: "sms",
      status: "sent",
      attempted_at: 5.minutes.ago
    )

    login_as @manager
    visit incident_path(incident)

    find("[data-testid='incident-status-trigger']").click
    find("[data-testid='incident-status-option-active']").click

    assert_text "Status updated."
    assert_equal "active", incident.reload.status
    escalation.reload
    assert escalation.resolved_at.present?
    assert_equal @manager.id, escalation.resolved_by_user_id
    assert_equal "incident_marked_active", escalation.resolution_reason
  end

  test "dfr pdf download works with expected filename" do
    ActivityEntry.create!(
      incident: @active_incident,
      performed_by_user: @manager,
      title: "Moisture readings and setup",
      occurred_at: Time.zone.parse("#{Date.current} 10:30")
    )

    login_as @manager
    visit incident_path(@active_incident)

    dfr_link = find("[data-testid='dfr-link-#{Date.current.iso8601}']", visible: :all)
    dfr_result = fetch_url_head(dfr_link[:href])

    assert_equal true, dfr_result["ok"]
    assert_includes dfr_result["content_type"], "application/pdf"
    assert_includes dfr_result["content_disposition"], "DFR-river-oaks-#{Date.current.iso8601}.pdf"
  end

  test "emergency incidents show distinct visual styling in list" do
    emergency = Incident.create!(
      property: @property_a,
      created_by_user: @manager,
      status: "acknowledged",
      project_type: "emergency_response",
      damage_type: "flood",
      description: "Emergency visual row test",
      emergency: true
    )
    standard = Incident.create!(
      property: @property_a,
      created_by_user: @manager,
      status: "acknowledged",
      project_type: "emergency_response",
      damage_type: "flood",
      description: "Standard visual row test",
      emergency: false
    )

    login_as @manager
    visit incidents_path

    emergency_row = find("tr", text: emergency.description)
    standard_row = find("tr", text: standard.description)

    assert_includes emergency_row.text, "Emergency"
    assert_includes emergency_row[:class].to_s, "bg-status-emergency/10"
    assert_includes standard_row.text, "Acknowledged"
    assert_not_includes standard_row[:class].to_s, "bg-status-emergency/10"
  end

  test "messages tab clears unread badge" do
    Message.create!(incident: @active_incident, user: @actor, body: "New message")

    login_as @manager
    visit incident_path(@active_incident)

    assert_tab_badge "Messages", "1"
    click_button "Messages"
    assert_no_tab_badge "Messages"
  end

  test "daily log tab clears activity unread badge" do
    ActivityEvent.create!(incident: @active_incident, performed_by_user: @actor, event_type: "activity_logged", metadata: {})

    login_as @manager
    visit incident_path(@active_incident)

    assert_tab_badge "Daily Log", "1"
    click_button "Daily Log"
    assert_no_tab_badge "Daily Log"
  end

  INCIDENT_CASES = {
    # Filled
  }.freeze

  INCIDENT_CASES.each do |id, description|
    test description do
      pending_e2e id, "Incident index/detail flows need stable filters/table selectors and deterministic seeded data"
    end
  end

  private

  def visible_property_names
    all("tbody tr td:first-child a").map { |node| node.text.strip }
  end

  def select_new_incident_org_and_property(org_name, property_name)
    comboboxes = all("[role='combobox']")
    comboboxes[0].click
    find("[role='option']", text: org_name).click
    comboboxes = all("[role='combobox']")
    comboboxes[1].click
    find("[role='option']", text: property_name).click
  end

  def open_radix_select(label_text)
    label = find("label", text: label_text, exact_text: false)
    label.find(:xpath, "./following::*[@role='combobox'][1]").click
  end

  def click_radix_option(text)
    find("[role='option']", text: text, exact_text: true).click
  end

  def submit_incident_patch(incident, description:)
    js = <<~JS
      const [path, description] = arguments;
      const token = document.querySelector('meta[name="csrf-token"]')?.content;
      const form = document.createElement('form');
      form.method = 'POST';
      form.action = path;
      const add = (n, v) => {
        const i = document.createElement('input');
        i.type = 'hidden';
        i.name = n;
        i.value = v;
        form.appendChild(i);
      };
      add('_method', 'patch');
      if (token) add('authenticity_token', token);
      add('incident[description]', description);
      document.body.appendChild(form);
      form.submit();
    JS
    page.execute_script(js, incident_path(incident), description)
  end

  def submit_transition_patch(incident, status)
    js = <<~JS
      const [path, status] = arguments;
      const token = document.querySelector('meta[name="csrf-token"]')?.content;
      const form = document.createElement('form');
      form.method = 'POST';
      form.action = path;
      const add = (n, v) => {
        const i = document.createElement('input');
        i.type = 'hidden';
        i.name = n;
        i.value = v;
        form.appendChild(i);
      };
      add('_method', 'patch');
      if (token) add('authenticity_token', token);
      add('status', status);
      document.body.appendChild(form);
      form.submit();
    JS
    page.execute_script(js, transition_incident_path(incident), status)
  end

  def fetch_url_head(url)
    js = <<~JS
      const [url, done] = arguments;
      fetch(url, { credentials: 'same-origin' })
        .then(async (resp) => {
          done({
            ok: resp.ok,
            content_type: resp.headers.get('content-type') || '',
            content_disposition: resp.headers.get('content-disposition') || ''
          });
        })
        .catch((e) => done({ ok: false, error: String(e), content_type: '', content_disposition: '' }));
    JS
    page.evaluate_async_script(js, url)
  end

  def assert_not_found_rendered
    production_404 = page.has_text?("The page you were looking for") && page.has_text?("exist")
    debug_404 = page.has_text?("ActiveRecord::RecordNotFound")
    assert(production_404 || debug_404, "Expected not-found response, got:\n#{page.text}")
  end

  def assert_tab_badge(label, count)
    tab = all("button").find { |b| b.text.include?(label) }
    assert tab, "Expected tab #{label}"
    within(tab) { assert_selector "span", text: count }
  end

  def assert_no_tab_badge(label)
    tab = all("button").find { |b| b.text.include?(label) }
    assert tab, "Expected tab #{label}"
    within(tab) { assert_no_selector "span" }
  end
end
