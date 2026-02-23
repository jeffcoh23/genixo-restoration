require "test_helper"

class AssignmentNotificationJobTest < ActiveSupport::TestCase
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @property = Property.create!(name: "Sunset Apts", mitigation_org: @genixo, property_management_org: @greystar)

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "Test", last_name: "Tech", password: "password123",
      notification_preferences: { "user_assignment" => true })

    @incident = Incident.create!(
      property: @property, created_by_user: @manager, status: "active",
      project_type: "emergency_response", damage_type: "flood", description: "Water damage", emergency: true
    )

    ActionMailer::Base.deliveries.clear
  end

  test "delivers assignment email to the assigned user" do
    assignment = @incident.incident_assignments.create!(user: @tech, assigned_by_user: @manager)

    perform_enqueued_jobs do
      AssignmentNotificationJob.perform_now(assignment.id)
    end
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal [ "tech@genixo.com" ], ActionMailer::Base.deliveries.last.to
  end

  test "skips inactive users" do
    assignment = @incident.incident_assignments.create!(user: @tech, assigned_by_user: @manager)
    @tech.update!(active: false)

    perform_enqueued_jobs do
      AssignmentNotificationJob.perform_now(assignment.id)
    end
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  test "does nothing if assignment is gone" do
    perform_enqueued_jobs do
      AssignmentNotificationJob.perform_now(0)
    end
    assert_equal 0, ActionMailer::Base.deliveries.size
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
