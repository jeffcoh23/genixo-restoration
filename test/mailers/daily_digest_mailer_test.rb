require "test_helper"

class DailyDigestMailerTest < ActionMailer::TestCase
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @user = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")

    @summaries = [
      {
        incident_id: 1,
        property_name: "Sunset Apartments",
        organization_name: "Greystar",
        status_label: "Active",
        new_messages: 3,
        new_activity_events: 2,
        new_labor_entries: 1,
        new_equipment_entries: 0
      },
      {
        incident_id: 2,
        property_name: "Oak Tower",
        organization_name: "Camden",
        status_label: "On Hold",
        new_messages: 0,
        new_activity_events: 1,
        new_labor_entries: 0,
        new_equipment_entries: 2
      }
    ]
    @date = Date.new(2026, 2, 18)
  end

  test "sends to correct recipient" do
    email = DailyDigestMailer.daily_digest(@user, @summaries, @date)
    assert_equal [ "mgr@genixo.com" ], email.to
  end

  test "has correct subject with date" do
    email = DailyDigestMailer.daily_digest(@user, @summaries, @date)
    assert_equal "Daily Activity Summary — February 18, 2026", email.subject
  end

  test "includes property names in body" do
    email = DailyDigestMailer.daily_digest(@user, @summaries, @date)
    assert_includes email.html_part.body.to_s, "Sunset Apartments"
    assert_includes email.html_part.body.to_s, "Oak Tower"
  end

  test "includes activity counts" do
    email = DailyDigestMailer.daily_digest(@user, @summaries, @date)
    body = email.html_part.body.to_s
    assert_includes body, "3 new messages"
    assert_includes body, "2 activity events"
    assert_includes body, "1 labor entry"
    assert_includes body, "2 equipment entries"
  end

  test "includes user greeting" do
    email = DailyDigestMailer.daily_digest(@user, @summaries, @date)
    assert_includes email.html_part.body.to_s, "Hi Test"
  end
end
