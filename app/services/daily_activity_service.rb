class DailyActivityService
  def initialize(incident:)
    @incident = incident
  end

  # Returns all dates that have activity, most recent first
  def activity_dates
    dates = Set.new

    @incident.labor_entries.pluck(:log_date).each { |d| dates << d }
    @incident.equipment_entries.pluck(:placed_at).each { |t| dates << t.to_date }
    @incident.equipment_entries.where.not(removed_at: nil).pluck(:removed_at).each { |t| dates << t.to_date }
    @incident.operational_notes.pluck(:log_date).each { |d| dates << d }
    @incident.attachments.where.not(log_date: nil).pluck(:log_date).each { |d| dates << d }
    @incident.activity_events.pluck(:created_at).each { |t| dates << t.to_date }

    dates.to_a.sort.reverse
  end

  # Returns all activity for a specific date
  def activity_for_date(date)
    range = date.all_day

    {
      labor_entries: @incident.labor_entries.includes(:user, :created_by_user)
                       .where(log_date: date)
                       .order(:created_at),
      equipment_entries: equipment_activity(date, range),
      operational_notes: @incident.operational_notes.includes(:created_by_user)
                           .where(log_date: date)
                           .order(:created_at),
      attachments: @incident.attachments.includes(:uploaded_by_user, file_attachment: :blob)
                     .where(log_date: date)
                     .order(:created_at),
      activity_events: @incident.activity_events.includes(:performed_by_user)
                         .where(created_at: range)
                         .order(:created_at)
    }
  end

  private

  def equipment_activity(date, range)
    placed = @incident.equipment_entries.includes(:equipment_type, :logged_by_user).where(placed_at: range)
    removed = @incident.equipment_entries.includes(:equipment_type, :logged_by_user).where(removed_at: range)
    (placed + removed).uniq.sort_by { |e| e.placed_at }
  end
end
