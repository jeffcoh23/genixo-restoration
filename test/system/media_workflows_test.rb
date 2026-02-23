require "application_system_test_case"
require_relative "planned_system_test_support"

class MediaWorkflowsTest < ApplicationSystemTestCase
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
      description: "Incident for media workflows")
    IncidentAssignment.create!(incident: @incident, user: @manager, assigned_by_user: @manager)
    IncidentAssignment.create!(incident: @incident, user: @tech, assigned_by_user: @manager)
  end

  test "photos panel includes incident and message image attachments with source marker" do
    create_incident_photo(@incident, @manager, "incident-photo.jpg")
    message = Message.create!(incident: @incident, user: @tech, body: "Photo from message")
    create_message_photo(message, @tech, "message-photo.jpg")

    login_as @manager
    visit incident_path(@incident)
    click_button "Photos"

    assert_text "incident-photo.jpg"
    assert_text "Photo from message"
    assert_text "MSG"
  end

  test "photos filters work at scale with deterministic pagination" do
    45.times do |i|
      uploader = i.even? ? @manager : @tech
      date = Date.current - (i % 3)
      create_incident_photo(@incident, uploader, "bulk-photo-#{i}.jpg", created_at: date.noon)
    end

    login_as @manager
    visit incident_path(@incident)
    click_button "Photos"

    assert_text "Showing 40 of 45"
    click_button "Load more"
    assert_text "Showing 45 of 45"

    fill_in "Search filename or note...", with: "bulk-photo-44"
    assert_text "1 of 45 photos"
    assert_text "Showing 1 of 1"

    fill_in "Search filename or note...", with: ""
    all("select").first.select("Tina Tech")
    assert_text "of 45 photos"
  end

  test "photo upload actions preserve scroll and panel state" do
    create_incident_photo(@incident, @manager, "seed-photo.jpg")

    login_as @manager
    visit incident_path(@incident)
    click_button "Photos"

    fill_in "Search filename or note...", with: "seed"
    assert_text "1 of 1 photos"
    assert_field "Search filename or note...", with: "seed"

    photo_upload_input = find("input[type='file'][accept='image/*'][multiple]", visible: false)
    assert_difference -> { @incident.attachments.where(category: "photo").count }, +1 do
      photo_upload_input.set(fixture_photo_path)
      assert_text "1 of 2 photos"
    end

    assert_text "Showing 1 of 1"
    assert_field "Search filename or note...", with: "seed"
    assert_button "Upload Photos"
    assert_button "Take Photos"

    fill_in "Search filename or note...", with: ""
    assert_text "test_photo.jpg"
  end

  test "take photos dialog gallery upload persists and returns to photos panel" do
    login_as @manager
    visit incident_path(@incident)
    click_button "Photos"
    click_button "Take Photos"

    within("[role='dialog']") do
      find("input[placeholder*='applies to all photos']").fill_in with: "Camera roll upload"

      gallery_input = find("input[type='file'][accept='image/*'][multiple]", visible: :all)

      assert_difference -> { @incident.attachments.where(category: "photo").count }, +1 do
        gallery_input.set(fixture_photo_path)
        assert_text "Latest: test_photo.jpg"
        assert_no_text "in progress"
      end

      click_button "Done"
    end

    assert_text "Camera roll upload"
    assert_button "Upload Photos"
    assert_button "Take Photos"
    uploaded_photo = @incident.attachments.order(:id).last
    assert_equal "photo", uploaded_photo.category
    assert uploaded_photo.file.filename.to_s.present?
    assert_equal "image/jpeg", uploaded_photo.file.blob.content_type
  end

  test "documents are grouped by type ordered and paginated" do
    32.times do |i|
      category = if i < 10
        "general"
      elsif i < 20
        "signed_document"
      else
        "moisture_mapping"
      end
      create_incident_document(@incident, @manager, "doc-#{i}.jpg", category: category, created_at: (Date.current - i.days).noon)
    end

    login_as @manager
    visit incident_path(@incident)
    click_button "Documents"

    assert_text "Showing 30 of 32"
    headers = all("section > div").map(&:text).select { |t| t.match?(/\A.+ \(\d+\)\z/) }
    mm_idx = headers.index { |t| t.start_with?("MOISTURE MAPPING") }
    sd_idx = headers.index { |t| t.start_with?("SIGNED DOCUMENT") }
    gen_idx = headers.index { |t| t.start_with?("GENERAL") }
    assert mm_idx && sd_idx && gen_idx, "Expected grouped category headers in documents panel, got: #{headers.inspect}"
    assert_operator mm_idx, :<, sd_idx
    assert_operator sd_idx, :<, gen_idx

    click_button "Load more"
    assert_text "Showing 32 of 32"
  end

  test "messages allow attachment only send" do
    login_as @manager
    visit incident_path(@incident)
    click_button "Messages"

    post_message_via_fetch(body: "", filename: "attachment-only.txt", content_type: "text/plain")
    assert_text "No entries for this date."
    click_button "Messages"
    assert_text "attachment-only.txt"
    last_message = @incident.messages.order(:id).last
    assert_equal "", last_message.body.to_s
    assert_equal 1, last_message.attachments.count
  end

  private

  def fixture_photo_path
    Rails.root.join("test/fixtures/files/test_photo.jpg")
  end

  def create_incident_photo(incident, user, filename, created_at: Time.current)
    create_attachment_record(attachable: incident, user: user, category: "photo", filename: filename, created_at: created_at)
  end

  def create_incident_document(incident, user, filename, category:, created_at: Time.current)
    create_attachment_record(attachable: incident, user: user, category: category, filename: filename, created_at: created_at)
  end

  def create_message_photo(message, user, filename, created_at: Time.current)
    create_attachment_record(
      attachable: message,
      user: user,
      category: "general",
      filename: filename,
      created_at: created_at,
      content_type: "image/svg+xml"
    )
  end

  def create_attachment_record(attachable:, user:, category:, filename:, created_at:, content_type: nil)
    content_type ||= if category == "photo"
      "image/svg+xml" # avoids thumbnail variant processing in test env without image_processing gem
    else
      "application/octet-stream"
    end

    attachment = Attachment.new(attachable: attachable, uploaded_by_user: user, category: category, created_at: created_at, updated_at: created_at)
    attachment.file.attach(io: File.open(fixture_photo_path), filename: filename, content_type: content_type)
    attachment.save!
    attachment
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
end
