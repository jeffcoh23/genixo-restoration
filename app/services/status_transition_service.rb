class StatusTransitionService
  class InvalidTransitionError < StandardError; end

  ALLOWED_TRANSITIONS = {
    "acknowledged" => %w[active quote_requested on_hold],
    "quote_requested" => %w[active closed],
    "active" => %w[on_hold completed],
    "on_hold" => %w[active completed],
    "completed" => %w[completed_billed active],
    "completed_billed" => %w[paid active],
    "paid" => %w[closed]
  }.freeze

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

      # TODO: Phase 5 — NotificationDispatchService for status change notifications
    end

    @incident
  end

  private

  def validate_transition!
    allowed = ALLOWED_TRANSITIONS[@incident.status]
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
