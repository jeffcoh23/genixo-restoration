require "application_system_test_case"
require_relative "planned_system_test_support"
require "tempfile"

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

  test "take photos dialog snap uploads using mocked camera and persists" do
    login_as @manager
    visit incident_path(@incident)
    click_button "Photos"

    install_mock_camera_for_snap

    find("[data-testid='photos-panel-take-photos-button']").click

    within("[role='dialog']") do
      find("[data-testid='photo-dialog-description']").fill_in with: "Snapped in dialog"
      assert_selector "[data-testid='photo-dialog-snap']"

      find("[data-testid='photo-dialog-snap']").click

      assert_text "Latest: photo-"
      assert_no_text "in progress"

      find("[data-testid='photo-dialog-done']").click
    end

    assert_text "Snapped in dialog"
    uploaded_photo = @incident.attachments.order(:id).last
    assert_equal "photo", uploaded_photo.category
    assert_equal "Snapped in dialog", uploaded_photo.description
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

  test "messages composer sends attachment only via file picker UI" do
    login_as @manager
    visit incident_path(@incident)
    click_button "Messages"

    with_temp_text_attachment("attachment-only") do |path, filename|
      find("[data-testid='message-file-input']", visible: :all).set(path)
      assert_no_selector "[data-testid='message-send'][disabled]"
      find("[data-testid='message-send']").click
      assert_no_text "No messages yet"
      assert_selector "a", text: filename
    end

    last_message = @incident.messages.order(:id).last
    assert_equal "", last_message.body.to_s
    assert_equal 1, last_message.attachments.count
    assert_equal "text/plain", last_message.attachments.first.file.blob.content_type
  end

  test "messages composer camera input sends image attachment via UI" do
    login_as @manager
    visit incident_path(@incident)
    click_button "Messages"

    find("[data-testid='message-camera-input']", visible: :all).set(fixture_photo_path.to_s)
    fill_in "Type a message...", with: "Photo from messages UI"

    assert_no_selector "[data-testid='message-send'][disabled]"
    find("[data-testid='message-send']").click

    assert_text "Photo from messages UI"
    assert_selector "a[title='test_photo.jpg']"

    last_message = @incident.messages.order(:id).last
    assert_equal "Photo from messages UI", last_message.body
    assert_equal 1, last_message.attachments.count
    assert_equal "image/jpeg", last_message.attachments.first.file.blob.content_type
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

  def with_temp_text_attachment(prefix)
    file = Tempfile.new([prefix, ".txt"])
    file.write("hello from ui e2e")
    file.flush
    yield file.path, File.basename(file.path)
  ensure
    file&.close
    file&.unlink
  end

  def install_mock_camera_for_snap
    js = <<~JS
      (() => {
        const jpegBase64 = "/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////2wBDAf//////////////////////////////////////////////////////////////////////////////////////wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAb/xAAVAQEBAAAAAAAAAAAAAAAAAAACAf/aAAwDAQACEAMQAAAB6AA//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABBQL/xAAVEQEBAAAAAAAAAAAAAAAAAAABAP/aAAgBAwEBPwF//8QAFBEBAAAAAAAAAAAAAAAAAAAAEP/aAAgBAgEBPwF//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQAGPwJ//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPyF//9k=";
        const bytes = Uint8Array.from(atob(jpegBase64), (c) => c.charCodeAt(0));
        const blob = new Blob([bytes], { type: "image/jpeg" });

        navigator.mediaDevices ||= {};
        navigator.mediaDevices.getUserMedia = async () => {
          if (typeof MediaStream !== "undefined") return new MediaStream();
          return { getTracks: () => [] };
        };

        if (!window.__e2ePatchedVideoDims) {
          window.__e2ePatchedVideoDims = true;
          Object.defineProperty(HTMLVideoElement.prototype, "videoWidth", {
            configurable: true,
            get() { return 640; }
          });
          Object.defineProperty(HTMLVideoElement.prototype, "videoHeight", {
            configurable: true,
            get() { return 480; }
          });
        }

        if (window.CanvasRenderingContext2D && !window.__e2ePatchedDrawImage) {
          window.__e2ePatchedDrawImage = true;
          const originalDrawImage = CanvasRenderingContext2D.prototype.drawImage;
          CanvasRenderingContext2D.prototype.drawImage = function(...args) {
            try {
              return originalDrawImage.apply(this, args);
            } catch (_e) {
              return undefined;
            }
          };
        }

        if (!window.__e2ePatchedCanvasToBlob) {
          window.__e2ePatchedCanvasToBlob = true;
          HTMLCanvasElement.prototype.toBlob = function(callback) {
            callback(blob);
          };
        }
      })();
    JS
    page.execute_script(js)
  end
end
