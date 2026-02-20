class StatusTransitionService
  class InvalidTransitionError < StandardError; end

  # Single transition map — standard and quote paths converge at "active"
  ALLOWED_TRANSITIONS = {
    # Intake — user picks the path
    "new" => %w[acknowledged proposal_requested],
    # Emergency/standard path
    "acknowledged" => %w[active on_hold],
    # Quote/proposal path
    "proposal_requested" => %w[proposal_submitted],
    "proposal_submitted" => %w[proposal_signed],
    "proposal_signed" => %w[active],
    # Shared from active onward
    "active" => %w[job_started on_hold],
    "job_started" => %w[completed on_hold],
    "on_hold" => %w[active job_started completed],
    "completed" => %w[completed_billed active],
    "completed_billed" => %w[paid active],
    "paid" => %w[closed]
  }.freeze

  def self.transitions_for(incident)
    ALLOWED_TRANSITIONS
  end

  def initialize(incident:, new_status:, user:)
    @incident = incident
    @new_status = new_status
    @user = user
  end

  def call
    validate_transition!

    ActiveRecord::Base.transaction do
      old_status = @incident.status
      @incident.update!(status: @new_status)

      ActivityLogger.log(
        incident: @incident, event_type: "status_changed", user: @user,
        metadata: { old_status: old_status, new_status: @new_status }
      )

      resolve_escalations if @new_status == "active"

      StatusChangeNotificationJob.perform_later(@incident.id, old_status, @new_status)
    end

    @incident
  end

  private

  def validate_transition!
    transitions = self.class.transitions_for(@incident)
    allowed = transitions[@incident.status]
    unless allowed&.include?(@new_status)
      raise InvalidTransitionError,
        "Cannot transition from '#{@incident.status}' to '#{@new_status}'"
    end
  end

  def resolve_escalations
    @incident.escalation_events.where(resolved_at: nil).find_each do |event|
      event.update!(
        resolved_at: Time.current,
        resolved_by_user: @user,
        resolution_reason: "incident_marked_active"
      )
    end
  end
end
