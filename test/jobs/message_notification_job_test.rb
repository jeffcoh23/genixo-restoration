require "test_helper"

class MessageNotificationJobTest < ActiveSupport::TestCase
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @property = Property.create!(name: "Sunset Apts", mitigation_org: @genixo, property_management_org: @greystar)

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "Test", last_name: "Tech", password: "password123")

    @incident = Incident.create!(
      property: @property, created_by_user: @manager, status: "active",
      project_type: "emergency_response", damage_type: "flood", description: "Water damage", emergency: true
    )
    @incident.incident_assignments.create!(user: @manager, assigned_by_user: @manager)
    @incident.incident_assignments.create!(user: @tech, assigned_by_user: @manager)

    ActionMailer::Base.deliveries.clear
  end

  test "delivers notification to all assigned users except sender" do
    message = @incident.messages.create!(user: @manager, body: "Update on the situation")

    perform_enqueued_jobs do
      MessageNotificationJob.perform_now(message.id)
    end
    # Manager is sender, so only tech gets notified
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal [ "tech@genixo.com" ], ActionMailer::Base.deliveries.last.to
  end

  test "skips users with new_message preference disabled" do
    @tech.update!(notification_preferences: { "new_message" => false })
    message = @incident.messages.create!(user: @manager, body: "Update on the situation")

    perform_enqueued_jobs do
      MessageNotificationJob.perform_now(message.id)
    end
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  test "does nothing if message is gone" do
    perform_enqueued_jobs do
      MessageNotificationJob.perform_now(0)
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
