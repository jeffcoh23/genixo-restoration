require "test_helper"

class AttachmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @sandalwood = Organization.create!(name: "Sandalwood", organization_type: "property_management")

    @property = Property.create!(
      name: "Sunset Apartments", property_management_org: @greystar,
      mitigation_org: @genixo
    )

    @manager = User.create!(organization: @genixo, user_type: User::MANAGER,
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: User::TECHNICIAN,
      email_address: "tech@genixo.com", first_name: "Test", last_name: "Tech", password: "password123")
    @pm_user = User.create!(organization: @greystar, user_type: User::PROPERTY_MANAGER,
      email_address: "pm@greystar.com", first_name: "Test", last_name: "PM", password: "password123")
    @cross_org_pm = User.create!(organization: @sandalwood, user_type: User::PROPERTY_MANAGER,
      email_address: "pm@sandalwood.com", first_name: "Cross", last_name: "PM", password: "password123")

    PropertyAssignment.create!(user: @pm_user, property: @property)

    @incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "flood", description: "Test incident", emergency: true
    )
    IncidentAssignment.create!(incident: @incident, user: @tech, assigned_by_user: @manager)
  end

  # --- Create tests ---

  test "manager can upload attachment" do
    login_as @manager
    assert_difference "Attachment.count", 1 do
      post incident_attachments_path(@incident), params: {
        attachment: {
          file: fixture_file_upload("test_photo.jpg", "image/jpeg"),
          category: "photo",
          description: "Water damage in bedroom",
          log_date: Date.current
        }
      }
    end
    assert_redirected_to incident_path(@incident)
    att = Attachment.last
    assert_equal "photo", att.category
    assert_equal "Water damage in bedroom", att.description
    assert_equal @manager.id, att.uploaded_by_user_id
    assert att.file.attached?
  end

  test "tech can upload attachment" do
    login_as @tech
    assert_difference "Attachment.count", 1 do
      post incident_attachments_path(@incident), params: {
        attachment: {
          file: fixture_file_upload("test_photo.jpg", "image/jpeg"),
          category: "moisture_readings",
          log_date: Date.current
        }
      }
    end
    assert_redirected_to incident_path(@incident)
    assert_equal @tech.id, Attachment.last.uploaded_by_user_id
  end

  test "PM user can upload attachment on visible incident" do
    login_as @pm_user
    assert_difference "Attachment.count", 1 do
      post incident_attachments_path(@incident), params: {
        attachment: {
          file: fixture_file_upload("test_photo.jpg", "image/jpeg"),
          category: "general"
        }
      }
    end
    assert_redirected_to incident_path(@incident)
  end

  test "cross-org PM user cannot upload attachment" do
    login_as @cross_org_pm
    assert_no_difference "Attachment.count" do
      post incident_attachments_path(@incident), params: {
        attachment: {
          file: fixture_file_upload("test_photo.jpg", "image/jpeg"),
          category: "photo"
        }
      }
    end
    assert_response :not_found
  end

  # --- Activity event + validation tests ---

  test "creates activity event on upload" do
    login_as @manager
    assert_difference "ActivityEvent.count", 1 do
      post incident_attachments_path(@incident), params: {
        attachment: {
          file: fixture_file_upload("test_photo.jpg", "image/jpeg"),
          category: "photo",
          description: "Before remediation"
        }
      }
    end
    event = ActivityEvent.last
    assert_equal "attachment_uploaded", event.event_type
    assert_equal @manager.id, event.performed_by_user_id
    assert_equal "test_photo.jpg", event.metadata["filename"]
    assert_equal "photo", event.metadata["category"]
    assert_not_nil @incident.reload.last_activity_at
  end

  test "returns error when category is invalid" do
    login_as @manager
    assert_no_difference "Attachment.count" do
      post incident_attachments_path(@incident), params: {
        attachment: {
          file: fixture_file_upload("test_photo.jpg", "image/jpeg"),
          category: "invalid_category"
        }
      }
    end
    assert_redirected_to incident_path(@incident)
    assert_equal "Could not upload file.", flash[:alert]
  end

  private

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end
end
