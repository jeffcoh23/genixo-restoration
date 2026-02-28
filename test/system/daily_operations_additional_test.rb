require "application_system_test_case"
require_relative "planned_system_test_support"

class DailyOperationsAdditionalTest < ApplicationSystemTestCase
  include PlannedSystemTestSupport

  setup do
    @mitigation = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @pm = Organization.create!(name: "Greystar", organization_type: "property_management")
    @property = Property.create!(name: "River Oaks", mitigation_org: @mitigation, property_management_org: @pm)

    @manager = User.create!(organization: @mitigation, user_type: User::MANAGER,
      email_address: "manager@example.com", first_name: "Mia", last_name: "Manager", password: "password123")
    @tech = User.create!(organization: @mitigation, user_type: User::TECHNICIAN,
      email_address: "tech@example.com", first_name: "Tina", last_name: "Tech", password: "password123")

    @incident = Incident.create!(property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response", damage_type: "flood",
      description: "Active incident for daily ops tests")
    IncidentAssignment.create!(incident: @incident, user: @manager, assigned_by_user: @manager)
    IncidentAssignment.create!(incident: @incident, user: @tech, assigned_by_user: @manager)

    @equipment_type = EquipmentType.create!(organization: @mitigation, name: "Dehumidifier")
    @equipment_item = EquipmentItem.create!(
      organization: @mitigation,
      equipment_type: @equipment_type,
      identifier: "DH-INV-01",
      equipment_model: "LGR 7000XLi"
    )
  end

  test "send message with attachment" do
    login_as @manager
    visit incident_path(@incident)
    click_button "Messages"

    post_message_via_fetch(body: "See attached file", filename: "note.txt", content_type: "text/plain")
    assert_text "No entries for this date."
    click_button "Messages"
    assert_text "See attached file"
    assert_text "note.txt"
    message = @incident.messages.order(:id).last
    assert_equal 1, message.attachments.count
  end

  test "manager logs labor for another user" do
    login_as @manager
    visit incident_path(@incident)
    click_button "Labor"
    click_button "Add Labor", match: :first

    within("[role='dialog']") do
      find("[role='combobox']").click
      fill_in "e.g. Technician, Supervisor", with: "Technician"
      find("input[type='date']").fill_in with: Date.current.iso8601
      all("input[type='time']")[0].fill_in with: "08:00"
      all("input[type='time']")[1].fill_in with: "12:00"
    end
    find("[role='option']", text: "Tina Tech (Technician)").click
    within("[role='dialog']") { click_button "Add Labor" }

    assert_text "Tina Tech"
    entry = @incident.labor_entries.order(:id).last
    assert_equal @tech.id, entry.user_id
    assert_equal 4.0, entry.hours.to_f
  end

  test "remove equipment entry" do
    entry = EquipmentEntry.create!(
      incident: @incident,
      logged_by_user: @manager,
      equipment_type: @equipment_type,
      equipment_model: "LGR 7000XLi",
      equipment_identifier: "DH-042",
      placed_at: Date.current,
      location_notes: "Unit 101 bedroom"
    )

    login_as @manager
    visit incident_path(@incident)
    click_button "Equipment"

    find("button[title='Mark as removed']").click

    assert_text "Equipment removed."
    assert entry.reload.removed_at.present?
  end

  test "log activity entry via daily log modal" do
    login_as @manager
    visit incident_path(@incident)
    click_button "Daily Log"
    click_button "Add Activity"

    within("[role='dialog']") do
      fill_in "e.g. Extract water", with: "Removed wet drywall in unit 101"
      fill_in "e.g. Active, On Hold - Waiting for reports", with: "Complete"
      find("[data-testid='activity-form-occurred-at']").fill_in with: Date.current.iso8601
      fill_in "e.g. 2", with: "2"
      fill_in "e.g. Units 237 and 239", with: "Units 101 and 102"
      fill_in "Detailed work performed — per-unit narratives, measurements, observations...", with: "Demo complete in kitchen and hallway."
      click_button "Add Activity"
    end

    assert_text "Activity added."
    assert_text "Removed wet drywall in unit 101"

    entry = @incident.activity_entries.order(:id).last
    assert_equal "Removed wet drywall in unit 101", entry.title
    assert_equal "Complete", entry.status
    assert_equal 2, entry.units_affected
    assert_equal "Units 101 and 102", entry.units_affected_description
    assert_equal "Demo complete in kitchen and hallway.", entry.details

    event = @incident.activity_events.order(:id).last
    assert_equal "activity_logged", event.event_type
  end

  test "upload document" do
    login_as @manager
    visit incident_path(@incident)
    click_button "Documents"
    click_button "Upload Document"

    within("[role='dialog']") do
      find("input[type='file']", visible: :all).set(fixture_photo_path.to_s)
      all("[role='combobox']").first.click
    end
    find("[role='option']", text: "Signed Document").click

    within("[role='dialog']") do
      fill_in "Optional description", with: "Signed work authorization"
      click_button "Upload"
    end

    assert_text "File uploaded."
    assert_text "Signed work authorization"
    assert_text "test_photo.jpg"
    attachment = @incident.attachments.order(:id).last
    assert_equal "signed_document", attachment.category
  end

  test "reject empty message" do
    login_as @manager
    visit incident_path(@incident)
    click_button "Messages"

    assert_selector "[data-testid='message-send'][disabled]"
    fill_in "Type a message...", with: "   "
    assert_selector "[data-testid='message-send'][disabled]"
    assert_equal 0, @incident.messages.count
    assert_text "No messages yet"
  end

  test "technician edits own labor entry" do
    entry = LaborEntry.create!(
      incident: @incident,
      created_by_user: @tech,
      user: @tech,
      role_label: "Technician",
      log_date: Date.current,
      started_at: Time.zone.parse("2026-02-23 08:00"),
      ended_at: Time.zone.parse("2026-02-23 10:00"),
      hours: 2.0,
      notes: "Initial extraction"
    )

    login_as @tech
    visit incident_path(@incident)
    click_button "Labor"

    submit_labor_entry_patch(
      entry,
      role_label: "Lead Technician",
      started_at: "2026-02-23T08:00:00-06:00",
      ended_at: "2026-02-23T12:00:00-06:00",
      notes: "Extended extraction work"
    )

    assert_text "Labor entry updated."
    assert_equal "Lead Technician", entry.reload.role_label
    assert_equal 4.0, entry.hours.to_f
    assert_equal "Extended extraction work", entry.notes
    assert_equal "labor_updated", @incident.activity_events.order(:id).last.event_type
  end

  test "manager deletes labor entry" do
    entry = LaborEntry.create!(
      incident: @incident,
      created_by_user: @tech,
      user: @tech,
      role_label: "Technician",
      log_date: Date.current,
      started_at: Time.zone.parse("2026-02-23 09:00"),
      ended_at: Time.zone.parse("2026-02-23 11:00"),
      hours: 2.0,
      notes: "Cleanup"
    )

    login_as @manager
    visit incident_path(@incident)
    click_button "Labor"

    submit_labor_entry_delete(entry)

    assert_text "Labor entry deleted."
    assert_nil LaborEntry.find_by(id: entry.id)
    assert_equal "labor_deleted", @incident.activity_events.order(:id).last.event_type
  end

  test "technician cannot edit another users labor entry" do
    entry = LaborEntry.create!(
      incident: @incident,
      created_by_user: @manager,
      user: @manager,
      role_label: "Supervisor",
      log_date: Date.current,
      started_at: Time.zone.parse("2026-02-23 08:00"),
      ended_at: Time.zone.parse("2026-02-23 12:00"),
      hours: 4.0,
      notes: "Manager entry"
    )

    login_as @tech
    visit incident_path(@incident)
    click_button "Labor"

    submit_labor_entry_patch(
      entry,
      role_label: "Technician",
      started_at: "2026-02-23T08:00:00-06:00",
      ended_at: "2026-02-23T09:00:00-06:00",
      notes: "Unauthorized edit"
    )

    assert_not_found_rendered
    entry.reload
    assert_equal "Supervisor", entry.role_label
    assert_equal "Manager entry", entry.notes
  end

  test "equipment placement uses inventory picker" do
    login_as @manager
    visit incident_path(@incident)
    click_button "Equipment"
    click_button "Add Equipment"

    within("[role='dialog']") do
      all("[role='combobox']").first.click
    end
    find("[role='option']", text: "Dehumidifier").click

    within("[role='dialog']") do
      all("[role='combobox']").last.click
    end
    find("[role='option']", text: /DH-INV-01/).click

    within("[role='dialog']") do
      fill_in "e.g. Unit 238, bedroom", with: "Unit 101 bedroom"
      click_button "Place Equipment"
    end

    assert_text "Equipment placed."
    assert_text "DH-INV-01"

    entry = @incident.equipment_entries.order(:id).last
    assert_equal @equipment_item.id, entry.equipment_item_id
    assert_equal "DH-INV-01", entry.equipment_identifier
    assert_equal "LGR 7000XLi", entry.equipment_model
    assert_equal "Unit 101 bedroom", entry.location_notes
  end

  test "equipment placement supports other custom type" do
    login_as @manager
    visit incident_path(@incident)
    click_button "Equipment"
    click_button "Add Equipment"

    within("[role='dialog']") do
      all("[role='combobox']").first.click
    end
    find("[role='option']", text: "Other (specify)").click

    within("[role='dialog']") do
      fill_in "e.g. Industrial Blower", with: "Air Scrubber"
      fill_in "e.g. LGR 7000XLi", with: "HEPA 500"
      fill_in "e.g. DH-042", with: "AS-12"
      fill_in "e.g. Unit 238, bedroom", with: "Hallway"
      click_button "Place Equipment"
    end

    assert_text "Equipment placed."
    assert_text "Air Scrubber"

    entry = @incident.equipment_entries.order(:id).last
    assert_nil entry.equipment_type_id
    assert_equal "Air Scrubber", entry.equipment_type_other
    assert_equal "AS-12", entry.equipment_identifier
  end

  test "edit equipment entry" do
    entry = EquipmentEntry.create!(
      incident: @incident,
      logged_by_user: @manager,
      equipment_type: @equipment_type,
      equipment_item: @equipment_item,
      equipment_model: "LGR 7000XLi",
      equipment_identifier: "DH-INV-01",
      placed_at: Date.current,
      location_notes: "Unit 101 bedroom"
    )

    login_as @manager
    visit incident_path(@incident)
    click_button "Equipment"

    row = find("tr", text: entry.equipment_identifier)
    within(row) { find("button[title='Edit']").click }

    within("[role='dialog']") do
      fill_in "e.g. Unit 238, bedroom", with: "Unit 101 living room"
      click_button "Update"
    end

    assert_text "Equipment entry updated."
    assert_equal "Unit 101 living room", entry.reload.location_notes
    assert_equal "equipment_updated", @incident.activity_events.order(:id).last.event_type
  end

  test "technician cannot edit another users equipment entry" do
    entry = EquipmentEntry.create!(
      incident: @incident,
      logged_by_user: @manager,
      equipment_type: @equipment_type,
      equipment_model: "LGR 7000XLi",
      equipment_identifier: "DH-999",
      placed_at: Date.current,
      location_notes: "Unit 202"
    )

    login_as @tech
    visit incident_path(@incident)
    click_button "Equipment"

    submit_equipment_entry_patch(entry, location_notes: "Unauthorized location")

    assert_not_found_rendered
    assert_equal "Unit 202", entry.reload.location_notes
  end

  test "add operational note" do
    login_as @manager
    visit incident_path(@incident)
    click_button "Daily Log"

    submit_operational_note(note_text: "Tenant requests after-hours update call", log_date: Date.current.iso8601)

    assert_text "Note added."
    assert_text "Operational note"
    assert_text "Tenant requests after-hours update call"

    note = @incident.operational_notes.order(:id).last
    assert_equal "Tenant requests after-hours update call", note.note_text
    assert_equal "operational_note_added", @incident.activity_events.order(:id).last.event_type
  end

  test "add incident contact" do
    login_as @manager
    visit incident_path(@incident)
    click_button "Manage"

    within(contacts_section) { click_button "Add" }

    within("[role='dialog']") do
      fill_in "Contact name", with: "Carla Contact"
      fill_in "e.g. Property Manager", with: "Resident Liaison"
      find("input[type='email']").set("carla@example.com")
      find("input[type='tel']").set("713-555-0199")
      click_button "Add Contact"
    end

    assert_text "Contact added."
    assert_text "Carla Contact"
    contact = @incident.incident_contacts.order(:id).last
    assert_equal "Resident Liaison", contact.title
    assert_equal "carla@example.com", contact.email
  end

  test "update incident contact" do
    contact = IncidentContact.create!(
      incident: @incident,
      created_by_user: @manager,
      name: "Carla Contact",
      title: "Resident Liaison",
      email: "carla@example.com",
      phone: "713-555-0100"
    )

    login_as @manager
    visit incident_path(@incident)
    click_button "Manage"

    find("button[title='Edit #{contact.name}']").click
    within("[role='dialog']") do
      find("input[type='tel']").set("713-555-0199")
      fill_in "e.g. Property Manager", with: "Property Liaison"
      click_button "Save"
    end

    assert_text "Contact updated."
    assert_text "Property Liaison"
    assert_equal "7135550199", contact.reload.phone
    assert_equal "Property Liaison", contact.title
  end

  test "remove incident contact" do
    contact = IncidentContact.create!(
      incident: @incident,
      created_by_user: @manager,
      name: "Remove Me",
      title: "Tenant",
      email: "remove@example.com"
    )

    login_as @manager
    visit incident_path(@incident)
    click_button "Manage"

    find("button[title='Remove #{contact.name}']").click

    assert_text "removed."
    within(contacts_section) { assert_no_text "Remove Me" }
    assert_nil IncidentContact.find_by(id: contact.id)
  end

  private

  def fixture_photo_path
    Rails.root.join("test/fixtures/files/test_photo.jpg")
  end

  def post_message_via_fetch(body:, filename:, content_type:)
    js = <<~JS
      const [path, body, filename, contentType] = arguments;
      const token = document.querySelector('meta[name=\"csrf-token\"]')?.content;
      const fd = new FormData();
      fd.append('message[body]', body);
      fd.append('message[files][]', new File(['hello from e2e'], filename, { type: contentType }));
      fetch(path, {
        method: 'POST',
        headers: token ? { 'X-CSRF-Token': token, 'X-Requested-With': 'XMLHttpRequest' } : { 'X-Requested-With': 'XMLHttpRequest' },
        body: fd
      }).then(() => window.location.reload());
    JS
    page.execute_script(js, incident_messages_path(@incident), body, filename, content_type)
  end

  def contacts_section
    all("section").find { |section| section.text.include?("Contacts") }
  end

  def submit_labor_entry_patch(entry, role_label:, started_at:, ended_at:, notes:)
    js = <<~JS
      const [path, roleLabel, startedAt, endedAt, notes] = arguments;
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
      addField('labor_entry[role_label]', roleLabel);
      addField('labor_entry[log_date]', startedAt.slice(0, 10));
      addField('labor_entry[started_at]', startedAt);
      addField('labor_entry[ended_at]', endedAt);
      addField('labor_entry[notes]', notes);
      document.body.appendChild(form);
      form.submit();
    JS
    page.execute_script(js, incident_labor_entry_path(@incident, entry), role_label, started_at, ended_at, notes)
  end

  def submit_labor_entry_delete(entry)
    js = <<~JS
      const [path] = arguments;
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
      addField('_method', 'delete');
      if (token) addField('authenticity_token', token);
      document.body.appendChild(form);
      form.submit();
    JS
    page.execute_script(js, incident_labor_entry_path(@incident, entry))
  end

  def submit_equipment_entry_patch(entry, location_notes:)
    js = <<~JS
      const [path, locationNotes] = arguments;
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
      addField('equipment_entry[equipment_type_id]', String(arguments[2]));
      addField('equipment_entry[equipment_model]', arguments[3]);
      addField('equipment_entry[equipment_identifier]', arguments[4]);
      addField('equipment_entry[placed_at]', arguments[5]);
      addField('equipment_entry[location_notes]', locationNotes);
      document.body.appendChild(form);
      form.submit();
    JS
    page.execute_script(
      js,
      incident_equipment_entry_path(@incident, entry),
      location_notes,
      entry.equipment_type_id,
      entry.equipment_model.to_s,
      entry.equipment_identifier.to_s,
      entry.placed_at.iso8601
    )
  end

  def submit_operational_note(note_text:, log_date:)
    js = <<~JS
      const [path, noteText, logDate] = arguments;
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
      addField('operational_note[note_text]', noteText);
      addField('operational_note[log_date]', logDate);
      document.body.appendChild(form);
      form.submit();
    JS
    page.execute_script(js, incident_operational_notes_path(@incident), note_text, log_date)
  end

  def assert_not_found_rendered
    production_404 = page.has_text?("The page you were looking for") && page.has_text?("exist")
    debug_404 = page.has_text?("ActiveRecord::RecordNotFound")
    assert(production_404 || debug_404, "Expected not-found response, got:\n#{page.text}")
  end
end
