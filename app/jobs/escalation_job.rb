class EscalationJob < ApplicationJob
  queue_as :urgent

  def perform(incident_id)
    incident = Incident.find_by(id: incident_id)
    return unless incident&.emergency?

    EscalationService.new(incident: incident, escalation_contact_index: 0).call
  end
end
