class EscalationTimeoutJob < ApplicationJob
  queue_as :urgent

  def perform(incident_id, next_index)
    incident = Incident.find_by(id: incident_id)
    return unless incident
    return if incident.status == "active"

    EscalationService.new(incident: incident, escalation_contact_index: next_index).call
  end
end
