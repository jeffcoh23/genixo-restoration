class DailyDigestJob < ApplicationJob
  queue_as :low

  def perform
    User.active.find_each do |user|
      next unless user.notification_preference("daily_digest")

      Time.use_zone(user.timezone) do
        yesterday = Time.current.to_date - 1
        range_start = yesterday.beginning_of_day
        range_end = yesterday.end_of_day

        incidents = Incident.visible_to(user)
          .where(last_activity_at: range_start..range_end)
          .includes(property: :property_management_org)

        next if incidents.empty?

        summaries = incidents.map { |incident| build_summary(incident, range_start, range_end) }

        DailyDigestMailer.daily_digest(user, summaries, yesterday).deliver_now
      end
    end
  end

  private

  def build_summary(incident, range_start, range_end)
    {
      incident_id: incident.id,
      property_name: incident.property.name,
      organization_name: incident.property.property_management_org.name,
      status_label: incident.display_status_label,
      new_messages: incident.messages.where(created_at: range_start..range_end).count,
      new_activity_events: incident.activity_events.where(created_at: range_start..range_end).count,
      new_labor_entries: incident.labor_entries.where(created_at: range_start..range_end).count,
      new_equipment_entries: incident.equipment_entries.where(created_at: range_start..range_end).count
    }
  end
end
