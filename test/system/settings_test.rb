require "application_system_test_case"
require_relative "planned_system_test_support"

class SettingsTest < ApplicationSystemTestCase
  include PlannedSystemTestSupport

  setup do
    @org = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @user = User.create!(
      organization: @org,
      user_type: User::MANAGER,
      email_address: "manager@example.com",
      first_name: "Mia",
      last_name: "Manager",
      timezone: "Central Time (US & Canada)",
      password: "password123"
    )
  end

  test "update profile fields and timezone" do
    login_as @user
    visit settings_path

    fill_in "First Name", with: "Mila"
    fill_in "Last Name", with: "Morris"
    fill_in "Email", with: "mila@example.com"

    # First combobox on settings page is the timezone select in the Profile form.
    find("[role='combobox']").click
    find("[role='option']", text: "(GMT-08:00) Pacific Time (US & Canada)").click

    click_button "Save Profile"

    assert_text "Profile updated."
    assert_equal "Mila", @user.reload.first_name
    assert_equal "Morris", @user.last_name
    assert_equal "mila@example.com", @user.email_address
    assert_equal "Pacific Time (US & Canada)", @user.timezone
  end

  test "change password happy path" do
    login_as @user
    visit settings_path

    fill_in "current_password", with: "password123"
    fill_in "password", with: "newpass123"
    fill_in "password_confirmation", with: "newpass123"
    click_button "Update Password"

    assert_text "Password updated."
    assert @user.reload.authenticate("newpass123"), "Expected password to be updated before logout/login verification"
    click_button "Log out"
    assert_current_path login_path
    assert_selector "input#email_address"

    fill_in "Email", with: @user.email_address
    fill_in "Password", with: "newpass123"
    click_button "Sign In"

    assert_text "Mia Manager"
  end

  test "change password rejects wrong current password" do
    login_as @user
    visit settings_path

    fill_in "current_password", with: "wrongpass"
    fill_in "password", with: "newpass123"
    fill_in "password_confirmation", with: "newpass123"
    click_button "Update Password"

    assert_text "Current password is incorrect."
    assert @user.reload.authenticate("password123")
    assert_not @user.authenticate("newpass123")
  end

  test "change password rejects mismatch confirmation" do
    login_as @user
    visit settings_path

    fill_in "current_password", with: "password123"
    fill_in "password", with: "newpass123"
    fill_in "password_confirmation", with: "different123"
    click_button "Update Password"

    assert_text "Password confirmation doesn't match."
    assert @user.reload.authenticate("password123")
    assert_not @user.authenticate("newpass123")
  end

  test "notification preferences persist" do
    @user.update!(notification_preferences: {
      "status_change" => true,
      "new_message" => true
    })

    login_as @user
    visit settings_path

    find("label[for='status_change']").click
    find("label[for='new_message']").click
    click_button "Save Preferences"

    assert_text "Notification preferences saved."
    prefs = @user.reload.notification_preferences
    assert_equal false, prefs["status_change"]
    assert_equal false, prefs["new_message"]
  end

  test "role and organization display are read only" do
    login_as @user
    visit settings_path

    assert_text "Manager at Genixo"
    assert_no_field "Role"
    assert_no_field "Organization"
    assert_no_button "Save Role"
    assert_no_button "Save Organization"
  end

  test "shows the mobile app card with the App Store link" do
    login_as @user
    visit settings_path

    assert_text "Get the mobile app"
    link = find_link("Download on the App Store")
    assert_equal MobileAppLinks.ios_app_store_url, link[:href]
  end

  test "shows the Android beta steps when the tester group url is configured" do
    with_env("ANDROID_TESTER_GROUP_URL" => "https://groups.google.com/g/genixo-android-testers") do
      login_as @user
      visit settings_path

      assert_text "Android (beta)"
      assert_link "Join the tester group", href: "https://groups.google.com/g/genixo-android-testers"
      assert_link "Install on Google Play", href: MobileAppLinks.android_opt_in_url
    end
  end

  SETTINGS_CASES = {
    # Filled
  }.freeze

  SETTINGS_CASES.each do |id, description|
    test description do
      pending_e2e id, "Settings UI selectors and copy need stable hooks before browser assertions are reliable"
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
