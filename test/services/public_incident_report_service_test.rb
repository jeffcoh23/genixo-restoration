require "test_helper"

class PublicIncidentReportServiceTest < ActiveSupport::TestCase
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @manager = User.create!(organization: @genixo, user_type: "manager", auto_assign: true,
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "Test", last_name: "Tech", password: "password123")

    @valid_params = {
      reporter_email: "reporter@example.com",
      reporter_name: "Jane Doe",
      reporter_phone: "5551234567",
      property_description: "Sunset Apartments, 123 Main St",
      project_type: "emergency_response",
      damage_type: "flood",
      description: "Water leaking from ceiling in unit 205",
      emergency: "1"
    }

    ActionMailer::Base.deliveries.clear
  end

  test "returns false with errors when required fields are blank" do
    service = PublicIncidentReportService.new({})
    assert_not service.call
    assert service.errors.key?("reporter_email")
    assert service.errors.key?("reporter_name")
    assert service.errors.key?("reporter_phone")
    assert service.errors.key?("property_description")
    assert service.errors.key?("project_type")
    assert service.errors.key?("damage_type")
    assert service.errors.key?("description")
  end

  test "returns false when email is invalid" do
    service = PublicIncidentReportService.new(@valid_params.merge(reporter_email: "not-an-email"))
    assert_not service.call
    assert_equal "is not a valid email address", service.errors["reporter_email"]
  end

  test "returns false when project_type is invalid" do
    service = PublicIncidentReportService.new(@valid_params.merge(project_type: "invalid"))
    assert_not service.call
    assert_equal "is not valid", service.errors["project_type"]
  end

  test "sends email to auto-assign users" do
    perform_enqueued_jobs do
      service = PublicIncidentReportService.new(@valid_params)
      assert service.call
    end
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal "mgr@genixo.com", ActionMailer::Base.deliveries.first.to.first
  end

  test "sends email to on-call primary user" do
    @manager.update!(auto_assign: false)
    OnCallConfiguration.create!(organization: @genixo, primary_user: @manager, escalation_timeout_minutes: 5)

    perform_enqueued_jobs do
      service = PublicIncidentReportService.new(@valid_params)
      assert service.call
    end
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  test "falls back to all managers when no auto-assign or on-call users" do
    @manager.update!(auto_assign: false)

    perform_enqueued_jobs do
      service = PublicIncidentReportService.new(@valid_params)
      assert service.call
    end
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  test "does not create an incident record" do
    assert_no_difference "Incident.count" do
      PublicIncidentReportService.new(@valid_params).call
    end
  end

  test "returns true even when no recipients found" do
    @genixo.destroy!
    service = PublicIncidentReportService.new(@valid_params)
    assert service.call
  end

  test "emergency email has emergency subject" do
    perform_enqueued_jobs do
      PublicIncidentReportService.new(@valid_params.merge(emergency: "1")).call
    end
    assert_includes ActionMailer::Base.deliveries.first.subject, "EMERGENCY"
  end

  test "non-emergency email has normal subject" do
    perform_enqueued_jobs do
      PublicIncidentReportService.new(@valid_params.merge(emergency: false)).call
    end
    assert_equal "New Public Incident Report Submitted", ActionMailer::Base.deliveries.first.subject
  end

  private

  def perform_enqueued_jobs(&block)
    ActiveJob::Base.queue_adapter = :test
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
    yield
  ensure
    ActiveJob::Base.queue_adapter = :solid_queue
  end
end
