require "test_helper"

class EscalationServiceTest < ActiveSupport::TestCase
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @property = Property.create!(name: "Sunset Apts", mitigation_org: @genixo, property_management_org: @greystar)

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123", phone: "555-0001")
    @backup = User.create!(organization: @genixo, user_type: "manager",
      email_address: "backup@genixo.com", first_name: "Backup", last_name: "Manager", password: "password123", phone: "555-0002")

    @incident = Incident.create!(
      property: @property, created_by_user: @manager, status: "acknowledged",
      project_type: "emergency_response", damage_type: "flood", description: "Water damage", emergency: true
    )

    ActionMailer::Base.deliveries.clear
  end

  # --- No on-call configuration ---

  test "logs escalation_skipped when no on-call config exists" do
    assert_difference "ActivityEvent.count", 1 do
      EscalationService.new(incident: @incident, escalation_contact_index: 0).call
    end

    event = ActivityEvent.last
    assert_equal "escalation_skipped", event.event_type
    assert_equal "no_on_call_configuration", event.metadata["reason"]
  end

  test "does not create escalation event when no on-call config" do
    assert_no_difference "EscalationEvent.count" do
      EscalationService.new(incident: @incident, escalation_contact_index: 0).call
    end
  end

  # --- With on-call configuration ---

  test "contacts primary on-call user at index 0" do
    create_on_call_config

    perform_enqueued_jobs do
      EscalationService.new(incident: @incident, escalation_contact_index: 0).call
    end

    assert_equal 1, EscalationEvent.count
    assert_equal @manager.id, EscalationEvent.last.user_id
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  test "creates activity event for escalation attempt" do
    create_on_call_config

    assert_difference "ActivityEvent.count", 1 do
      perform_enqueued_jobs do
        EscalationService.new(incident: @incident, escalation_contact_index: 0).call
      end
    end

    event = ActivityEvent.last
    assert_equal "escalation_attempted", event.event_type
    assert_equal 0, event.metadata["contact_index"]
  end

  test "contacts escalation chain user at index > 0" do
    config = create_on_call_config
    EscalationContact.create!(on_call_configuration: config, user: @backup, position: 1)

    perform_enqueued_jobs do
      EscalationService.new(incident: @incident, escalation_contact_index: 1).call
    end

    assert_equal 1, EscalationEvent.count
    assert_equal @backup.id, EscalationEvent.last.user_id
  end

  test "logs escalation_exhausted when contact list is exhausted" do
    create_on_call_config

    assert_difference "ActivityEvent.count", 1 do
      EscalationService.new(incident: @incident, escalation_contact_index: 1).call
    end

    event = ActivityEvent.last
    assert_equal "escalation_exhausted", event.event_type
    assert_equal 1, event.metadata["contacts_tried"]
  end

  test "sends SMS when user has phone number" do
    create_on_call_config

    # NotificationService.send_sms is a log-only stub — just ensure no errors
    assert_nothing_raised do
      perform_enqueued_jobs do
        EscalationService.new(incident: @incident, escalation_contact_index: 0).call
      end
    end
  end

  private

  def create_on_call_config
    OnCallConfiguration.create!(
      organization: @genixo,
      primary_user: @manager,
      escalation_timeout_minutes: 10
    )
  end

  def perform_enqueued_jobs(&block)
    ActiveJob::Base.queue_adapter = :test
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
    yield
  ensure
    ActiveJob::Base.queue_adapter = :solid_queue
  end
end
