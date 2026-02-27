class DashboardService
  def initialize(user:)
    @user = user
  end

  def grouped_incidents
    all = base_scope.to_a

    {
      emergency: all.select { |i| i.emergency && %w[new acknowledged].include?(i.status) },
      active: all.select { |i| i.status == "active" },
      needs_attention: all.select { |i| %w[new acknowledged proposal_requested proposal_submitted proposal_signed].include?(i.status) && !i.emergency },
      on_hold: all.select { |i| i.status == "on_hold" },
      recent_completed: all.select { |i| %w[completed completed_billed paid closed proposal_completed].include?(i.status) }
        .first(20)
    }
  end

  # Returns { incident_id => { messages: N, activity: N } } for incidents with unread content
  def unread_counts
    visible_ids = Incident.visible_to(@user).select(:id)
    unread_counts_for(visible_ids)
  end

  # Scoped version: only compute for specific incident IDs (used for paginated lists)
  def unread_counts_for(incident_ids)
    read_states = IncidentReadState.where(user: @user, incident_id: incident_ids)
      .index_by(&:incident_id)

    counts = {}

    # Single grouped query for messages — no per-incident COUNTs
    Message.where(incident_id: incident_ids)
      .where.not(user_id: @user.id)
      .group(:incident_id)
      .select("incident_id, COUNT(*) AS total, MAX(created_at) AS latest")
      .each do |row|
      rs = read_states[row.incident_id]
      threshold = rs&.last_message_read_at
      next unless threshold.nil? || row.latest > threshold

      unread = if threshold
        Message.where(incident_id: row.incident_id)
          .where.not(user_id: @user.id)
          .where("created_at > ?", threshold).count
      else
        row.total
      end
      next unless unread > 0
      counts[row.incident_id] ||= { messages: 0, activity: 0 }
      counts[row.incident_id][:messages] = unread
    end

    # Single grouped query for activity events
    ActivityEvent.where(incident_id: incident_ids)
      .for_daily_log_notifications
      .where.not(performed_by_user_id: @user.id)
      .group(:incident_id)
      .select("incident_id, COUNT(*) AS total, MAX(created_at) AS latest")
      .each do |row|
      rs = read_states[row.incident_id]
      threshold = rs&.last_activity_read_at
      next unless threshold.nil? || row.latest > threshold

      unread = if threshold
        ActivityEvent.where(incident_id: row.incident_id)
          .for_daily_log_notifications
          .where.not(performed_by_user_id: @user.id)
          .where("created_at > ?", threshold).count
      else
        row.total
      end
      next unless unread > 0
      counts[row.incident_id] ||= { messages: 0, activity: 0 }
      counts[row.incident_id][:activity] = unread
    end

    counts
  end

  private

  def base_scope
    Incident.visible_to(@user)
      .includes(property: :property_management_org)
      .order(last_activity_at: :desc)
  end
end
