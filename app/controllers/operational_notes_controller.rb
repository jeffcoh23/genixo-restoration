class OperationalNotesController < ApplicationController
  before_action :set_incident
  before_action :authorize_notes!

  def create
    note = @incident.operational_notes.new(note_params)
    note.created_by_user = current_user

    note.save!

    ActivityLogger.log(
      incident: @incident,
      event_type: "operational_note_added",
      user: current_user,
      metadata: {
        note_preview: note.note_text.truncate(80)
      }
    )

    redirect_to incident_path(@incident), notice: "Note added."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to incident_path(@incident),
      inertia: { errors: e.record.errors.to_hash },
      alert: "Could not add note."
  end

  private

  def set_incident
    @incident = find_visible_incident!(params[:incident_id])
  end

  def authorize_notes!
    raise ActiveRecord::RecordNotFound unless can_create_operational_note?
  end

  def note_params
    params.require(:operational_note).permit(:note_text, :log_date)
  end
end
