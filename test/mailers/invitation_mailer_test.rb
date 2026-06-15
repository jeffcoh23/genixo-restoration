require "test_helper"

class InvitationMailerTest < ActionMailer::TestCase
  setup do
    @org = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @invitation = Invitation.create!(
      email: "newuser@example.com",
      user_type: "technician",
      organization: @org,
      invited_by_user: User.create!(organization: @org, user_type: "manager",
        email_address: "mgr@genixo.com", first_name: "M", last_name: "Gr", password: "password123"),
      expires_at: 7.days.from_now
    )
  end

  test "always includes the accept invitation link" do
    mail = InvitationMailer.invite(@invitation)
    assert_includes mail.html_part.body.to_s, "Accept Invitation"
    assert_includes mail.text_part.body.to_s, "Accept your invitation:"
  end

  test "omits the Android block when ANDROID_TESTER_GROUP_URL is not set" do
    with_env("ANDROID_TESTER_GROUP_URL" => nil) do
      mail = InvitationMailer.invite(@invitation)
      refute_includes mail.html_part.body.to_s, "On an Android phone"
      refute_includes mail.text_part.body.to_s, "On an Android phone"
    end
  end

  test "includes the Android block with both links when the group URL is set" do
    group_url = "https://groups.google.com/g/genixo-android-testers"
    with_env("ANDROID_TESTER_GROUP_URL" => group_url, "ANDROID_OPT_IN_URL" => nil) do
      mail = InvitationMailer.invite(@invitation)

      html = mail.html_part.body.to_s
      assert_includes html, "On an Android phone"
      assert_includes html, group_url
      assert_includes html, "https://play.google.com/apps/testing/com.genixo.restoration"

      text = mail.text_part.body.to_s
      assert_includes text, "On an Android phone"
      assert_includes text, group_url
      assert_includes text, "https://play.google.com/apps/testing/com.genixo.restoration"
    end
  end

  test "honors a custom ANDROID_OPT_IN_URL override" do
    with_env(
      "ANDROID_TESTER_GROUP_URL" => "https://groups.google.com/g/genixo-android-testers",
      "ANDROID_OPT_IN_URL" => "https://example.com/custom-optin"
    ) do
      mail = InvitationMailer.invite(@invitation)
      assert_includes mail.html_part.body.to_s, "https://example.com/custom-optin"
    end
  end

  private

  def with_env(values)
    originals = values.each_key.to_h { |k| [ k, ENV[k] ] }
    values.each { |k, v| ENV[k] = v }
    yield
  ensure
    originals.each { |k, v| ENV[k] = v }
  end
end
