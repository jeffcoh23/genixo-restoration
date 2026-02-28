require "test_helper"

class DfrPdfJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @property = Property.create!(name: "Sunset Apts", mitigation_org: @genixo, property_management_org: @greystar)

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")

    @incident = Incident.create!(property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response", damage_type: "flood", description: "Test DFR")
  end

  test "creates an attachment with generated PDF" do
    date = Date.current.to_s

    assert_difference -> { @incident.attachments.count }, 1 do
      DfrPdfJob.perform_now(@incident.id, date, "America/Chicago", @manager.id)
    end

    attachment = @incident.attachments.last
    assert_equal "dfr", attachment.category
    assert attachment.file.attached?
    assert_includes attachment.file.filename.to_s, "DFR-"
    assert_equal "application/pdf", attachment.file.content_type
    assert_equal date, attachment.log_date.to_s
  end

  test "uses incident job_id in filename when available" do
    @incident.update!(job_id: "JOB-123")
    date = Date.current.to_s

    DfrPdfJob.perform_now(@incident.id, date, "America/Chicago", @manager.id)

    attachment = @incident.attachments.last
    assert_includes attachment.file.filename.to_s, "DFR-JOB-123"
  end

  test "sets description with date" do
    date = Date.current.to_s
    DfrPdfJob.perform_now(@incident.id, date, "America/Chicago", @manager.id)

    attachment = @incident.attachments.last
    assert_includes attachment.description, date
  end
end
