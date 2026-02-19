require "test_helper"

class DailyDigestJobTest < ActiveSupport::TestCase
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")

    @property = Property.create!(name: "Sunset Apts", mitigation_org: @genixo, property_management_org: @greystar)

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123",
      notification_preferences: { "daily_digest" => true })

    @manager_no_digest = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr2@genixo.com", first_name: "No", last_name: "Digest", password: "password123",
      notification_preferences: { "daily_digest" => false })

    @incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "flood", description: "Test incident",
      last_activity_at: yesterday_noon
    )

    ActionMailer::Base.deliveries.clear
  end

  test "sends digest to users with preference enabled" do
    Message.create!(incident: @incident, user: @manager_no_digest, body: "Hello", created_at: yesterday_noon)

    DailyDigestJob.perform_now

    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal [ "mgr@genixo.com" ], ActionMailer::Base.deliveries.first.to
  end

  test "skips users with digest preference disabled" do
    Message.create!(incident: @incident, user: @manager, body: "Hello", created_at: yesterday_noon)

    DailyDigestJob.perform_now

    recipients = ActionMailer::Base.deliveries.map(&:to).flatten
    assert_includes recipients, "mgr@genixo.com"
    assert_not_includes recipients, "mgr2@genixo.com"
  end

  test "skips users with no activity on their incidents yesterday" do
    # last_activity_at is yesterday, but no messages/events were created yesterday
    # so there's still an incident with activity — need to set it to older
    @incident.update!(last_activity_at: 3.days.ago)

    DailyDigestJob.perform_now

    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  test "uses user timezone for yesterday calculation" do
    @manager.update!(timezone: "Eastern Time (US & Canada)")

    eastern = ActiveSupport::TimeZone["Eastern Time (US & Canada)"]
    yesterday_in_eastern = (eastern.now.to_date - 1).in_time_zone(eastern).change(hour: 14)

    Message.create!(incident: @incident, user: @manager_no_digest, body: "Late message", created_at: yesterday_in_eastern)
    @incident.update!(last_activity_at: yesterday_in_eastern)

    DailyDigestJob.perform_now

    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  private

  # "Yesterday at noon" in the user's default timezone (America/Chicago)
  def yesterday_noon
    tz = ActiveSupport::TimeZone[@manager.timezone]
    (tz.now.to_date - 1).in_time_zone(tz).change(hour: 12)
  end
end
