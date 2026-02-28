require "application_system_test_case"

class BatchImprovementsTest < ApplicationSystemTestCase
  setup do
    @mitigation = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @pm = Organization.create!(name: "Greystar", organization_type: "property_management")
    @property = Property.create!(
      name: "Sunset Apartments", property_management_org: @pm,
      mitigation_org: @mitigation, street_address: "100 Sunset Blvd",
      city: "Houston", state: "TX", zip: "77001", unit_count: 24
    )

    @manager = User.create!(organization: @mitigation, user_type: User::MANAGER,
      email_address: "manager@example.com", first_name: "Mia", last_name: "Manager",
      phone: "2032180897", password: "password123")
    @tech = User.create!(organization: @mitigation, user_type: User::TECHNICIAN,
      email_address: "tech@example.com", first_name: "Tina", last_name: "Tech",
      password: "password123")
    @pm_user = User.create!(organization: @pm, user_type: "property_manager",
      email_address: "pm@greystar.com", first_name: "Pat", last_name: "PMgr",
      password: "password123")

    PropertyAssignment.create!(user: @pm_user, property: @property)

    @incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "flood", description: "Water intrusion test incident"
    )
    IncidentAssignment.create!(incident: @incident, user: @manager, assigned_by_user: @manager)
    IncidentAssignment.create!(incident: @incident, user: @tech, assigned_by_user: @manager)
    IncidentAssignment.create!(incident: @incident, user: @pm_user, assigned_by_user: @manager)
  end

  # --- Item 1: Phone formatting ---

  test "formatted phone displays in manage tab team section" do
    login_as @manager
    visit incident_path(@incident)
    click_button "Manage"

    # Click manager name to expand contact info
    click_button "Mia Manager"
    assert_text "(203) 218-0897"
  end

  test "formatted phone tel link contains digits only" do
    login_as @manager
    visit incident_path(@incident)
    click_button "Manage"
    click_button "Mia Manager"

    phone_link = first("a[href^='tel:']")
    assert_match(/^tel:\d+$/, phone_link["href"])
  end

  # --- Item 3: Hide closed incidents ---

  test "closed incidents hidden from index by default" do
    Incident.create!(
      property: @property, created_by_user: @manager,
      status: "closed", project_type: "emergency_response",
      damage_type: "flood", description: "This one is closed already"
    )

    login_as @manager
    visit incidents_path

    assert_text "Water intrusion test incident"
    assert_no_text "This one is closed already"
    assert_text "Closed incidents hidden"
  end

  test "show closed link reveals closed incidents" do
    Incident.create!(
      property: @property, created_by_user: @manager,
      status: "closed", project_type: "emergency_response",
      damage_type: "flood", description: "This one is closed already"
    )

    login_as @manager
    visit incidents_path

    click_button "Show closed"
    assert_text "This one is closed already"
  end

  # --- Items 4+6: Attachment permissions ---

  test "PM user does not see upload buttons on photos panel" do
    create_incident_photo(@incident, @manager, "test-photo.jpg")

    login_as @pm_user
    visit incident_path(@incident)
    click_button "Photos"

    assert_text "test-photo.jpg"
    assert_no_button "Upload Photos"
    assert_no_button "Take Photos"
  end

  test "PM user does not see upload button on documents panel" do
    create_incident_document(@incident, @manager, "test-doc.pdf", category: "general")

    login_as @pm_user
    visit incident_path(@incident)
    click_button "Documents"

    assert_text "test-doc.pdf"
    assert_no_button "Upload Document"
  end

  test "mitigation user sees upload buttons on photos panel" do
    login_as @manager
    visit incident_path(@incident)
    click_button "Photos"

    assert_button "Upload Photos"
    assert_button "Take Photos"
  end

  test "mitigation user can edit photo description and date" do
    photo = create_incident_photo(@incident, @manager, "editable-photo.jpg")

    login_as @manager
    visit incident_path(@incident)
    click_button "Photos"

    # Hover over the photo card to reveal edit button
    card = find("[class*='group']", text: "editable-photo.jpg")
    card.hover
    card.find("button[title='Edit photo']").click

    within("[role='dialog']") do
      assert_text "Edit Photo"
      fill_in "Description", with: "Updated description"
      fill_in "Date", with: "2026-02-15"
      click_button "Save"
    end

    # Wait for dialog to close (Inertia save completes)
    assert_no_selector "[role='dialog']"

    photo.reload
    assert_equal "Updated description", photo.description
    assert_equal Date.parse("2026-02-15"), photo.log_date
  end

  test "mitigation user can delete photo with confirmation" do
    create_incident_photo(@incident, @manager, "deletable-photo.jpg")

    login_as @manager
    visit incident_path(@incident)
    click_button "Photos"

    card = find("[class*='group']", text: "deletable-photo.jpg")
    card.hover
    card.find("button[title='Delete photo']").click

    within("[role='dialog']") do
      assert_text "Delete Photo"
      assert_text "deletable-photo.jpg"
      click_button "Delete"
    end

    # Wait for Inertia page reload after delete
    assert_no_selector "[role='dialog']"
    assert_text "Photos"
    assert_equal 0, @incident.reload.attachments.where(category: "photo").count
  end

  # --- Item 7: PM manage tab visibility ---

  test "PM user does not see mitigation team section in manage tab" do
    login_as @pm_user
    visit incident_path(@incident)
    click_button "Manage"

    assert_text "Property Management"
    assert_text "Contacts"
    assert_no_text "Mitigation Team"
  end

  test "mitigation user sees all three sections in manage tab" do
    login_as @manager
    visit incident_path(@incident)
    click_button "Manage"

    assert_text "Mitigation Team"
    assert_text "Property Management"
    assert_text "Contacts"
  end

  # --- Item 2: DFR in daily log ---

  test "DFR generate button shows Processing state after click" do
    create_activity_for_date(@incident, @manager, Date.current)

    login_as @manager
    visit incident_path(@incident)
    # Daily Log is the default tab
    assert_selector "[data-testid^='dfr-generate-']"
    assert_no_selector "[data-testid^='dfr-link-']"

    # Click generate — should show Processing...
    find("[data-testid^='dfr-generate-']").click
    assert_selector "[data-testid^='dfr-processing-']"
    assert_text "Processing..."
  end

  test "DFR shows as download link when DFR attachment exists" do
    date = Date.current
    create_activity_for_date(@incident, @manager, date)

    # Create a DFR attachment for today
    att = Attachment.new(attachable: @incident, uploaded_by_user: @manager,
      category: "dfr", log_date: date, description: "DFR")
    att.file.attach(io: StringIO.new("fake pdf"), filename: "DFR-test.pdf", content_type: "application/pdf")
    att.save!

    login_as @manager
    visit incident_path(@incident)

    assert_selector "a[data-testid='dfr-link-#{date.iso8601}']"
    link = find("a[data-testid='dfr-link-#{date.iso8601}']")
    assert_text "DFR"
    assert link["href"].present?
  end

  test "DFR does not appear in documents panel" do
    date = Date.current
    att = Attachment.new(attachable: @incident, uploaded_by_user: @manager,
      category: "dfr", log_date: date, description: "Daily Field Report")
    att.file.attach(io: StringIO.new("fake pdf"), filename: "DFR-test.pdf", content_type: "application/pdf")
    att.save!

    # Also add a normal document so the panel has content
    create_incident_document(@incident, @manager, "normal-doc.pdf", category: "general")

    login_as @manager
    visit incident_path(@incident)
    click_button "Documents"

    assert_text "normal-doc.pdf"
    assert_no_text "DFR-test.pdf"
  end

  private

  def fixture_photo_path
    Rails.root.join("test/fixtures/files/test_photo.jpg")
  end

  def create_incident_photo(incident, user, filename, created_at: Time.current)
    att = Attachment.new(attachable: incident, uploaded_by_user: user, category: "photo",
      created_at: created_at, updated_at: created_at)
    att.file.attach(io: File.open(fixture_photo_path), filename: filename, content_type: "image/svg+xml")
    att.save!
    att
  end

  def create_incident_document(incident, user, filename, category:, created_at: Time.current)
    att = Attachment.new(attachable: incident, uploaded_by_user: user, category: category,
      created_at: created_at, updated_at: created_at)
    att.file.attach(io: File.open(fixture_photo_path), filename: filename, content_type: "application/octet-stream")
    att.save!
    att
  end

  def create_activity_for_date(incident, user, date)
    ActivityEntry.create!(
      incident: incident,
      performed_by_user: user,
      title: "Site inspection",
      status: "in_progress",
      occurred_at: date.noon
    )
  end
end
