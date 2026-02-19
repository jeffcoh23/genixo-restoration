class DashboardService
  def initialize(user:)
    @user = user
  end

  def grouped_incidents
    scope = base_scope

    {
      emergency: scope.where(emergency: true, status: %w[new acknowledged active]),
      active: scope.where(status: "active", emergency: false),
      needs_attention: scope.where(status: %w[new acknowledged proposal_requested proposal_submitted proposal_signed], emergency: false),
      on_hold: scope.where(status: "on_hold"),
      recent_completed: scope.where(status: %w[completed completed_billed paid closed proposal_completed]).limit(20)
    }
  end

  # Returns { incident_id => { messages: N, activity: N } } for incidents with unread content
  def unread_counts
    visible_ids = Incident.visible_to(@user).select(:id)

    read_states = IncidentReadState.where(user: @user, incident_id: visible_ids)
      .index_by(&:incident_id)

    counts = {}

    # Unread messages: messages created after user's last_message_read_at
    Message.where(incident_id: visible_ids)
      .where.not(user_id: @user.id)
      .group(:incident_id)
      .select("incident_id, MAX(created_at) AS latest, COUNT(*) AS total")
      .each do |row|
      rs = read_states[row.incident_id]
      threshold = rs&.last_message_read_at
      counts[row.incident_id] ||= { messages: 0, activity: 0 }
      if threshold.nil? || row.latest > threshold
        # Need exact count after threshold
        unread = if threshold
          Message.where(incident_id: row.incident_id)
            .where.not(user_id: @user.id)
            .where("created_at > ?", threshold).count
        else
          row.total
        end
        counts[row.incident_id][:messages] = unread if unread > 0
      end
    end

    # Unread activity: activity_events created after user's last_activity_read_at
    ActivityEvent.where(incident_id: visible_ids)
      .where.not(performed_by_user_id: @user.id)
      .group(:incident_id)
      .select("incident_id, MAX(created_at) AS latest, COUNT(*) AS total")
      .each do |row|
      rs = read_states[row.incident_id]
      threshold = rs&.last_activity_read_at
      counts[row.incident_id] ||= { messages: 0, activity: 0 }
      if threshold.nil? || row.latest > threshold
        unread = if threshold
          ActivityEvent.where(incident_id: row.incident_id)
            .where.not(performed_by_user_id: @user.id)
            .where("created_at > ?", threshold).count
        else
          row.total
        end
        counts[row.incident_id][:activity] = unread if unread > 0
      end
    end

    # Only return incidents that actually have unread content
    counts.select { |_, v| v[:messages] > 0 || v[:activity] > 0 }
  end

  private

  def base_scope
    Incident.visible_to(@user)
      .includes(property: :property_management_org)
      .order(last_activity_at: :desc)
  end
end
