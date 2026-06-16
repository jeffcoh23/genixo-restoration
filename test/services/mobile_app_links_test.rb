require "test_helper"

class MobileAppLinksTest < ActiveSupport::TestCase
  IOS_DEFAULT = "https://apps.apple.com/us/app/genixo-restoration/id6760802383".freeze
  ANDROID_OPT_IN_DEFAULT = "https://play.google.com/apps/testing/com.genixo.restoration".freeze
  GROUP_URL = "https://groups.google.com/g/genixo-android-testers".freeze

  test "ios_app_store_url falls back to the App Store default when env is unset" do
    with_env("IOS_APP_STORE_URL" => nil) do
      assert_equal IOS_DEFAULT, MobileAppLinks.ios_app_store_url
    end
  end

  test "ios_app_store_url honors the IOS_APP_STORE_URL override" do
    with_env("IOS_APP_STORE_URL" => "https://example.com/ios") do
      assert_equal "https://example.com/ios", MobileAppLinks.ios_app_store_url
    end
  end

  test "android_tester_group_url is nil when env is unset" do
    with_env("ANDROID_TESTER_GROUP_URL" => nil) do
      assert_nil MobileAppLinks.android_tester_group_url
    end
  end

  test "android_tester_group_url returns the configured value" do
    with_env("ANDROID_TESTER_GROUP_URL" => GROUP_URL) do
      assert_equal GROUP_URL, MobileAppLinks.android_tester_group_url
    end
  end

  test "android_opt_in_url falls back to the Play default when env is unset" do
    with_env("ANDROID_OPT_IN_URL" => nil) do
      assert_equal ANDROID_OPT_IN_DEFAULT, MobileAppLinks.android_opt_in_url
    end
  end

  test "android_opt_in_url honors the ANDROID_OPT_IN_URL override" do
    with_env("ANDROID_OPT_IN_URL" => "https://example.com/optin") do
      assert_equal "https://example.com/optin", MobileAppLinks.android_opt_in_url
    end
  end

  test "android_beta? is false when the group url is unset" do
    with_env("ANDROID_TESTER_GROUP_URL" => nil) do
      assert_not MobileAppLinks.android_beta?
    end
  end

  test "android_beta? is true when the group url is set" do
    with_env("ANDROID_TESTER_GROUP_URL" => GROUP_URL) do
      assert MobileAppLinks.android_beta?
    end
  end

  test "to_props returns the exact shape the Settings page consumes" do
    with_env("IOS_APP_STORE_URL" => nil, "ANDROID_TESTER_GROUP_URL" => GROUP_URL, "ANDROID_OPT_IN_URL" => nil) do
      props = MobileAppLinks.to_props
      assert_equal %i[ios_url android_group_url android_opt_in_url].sort, props.keys.sort
      assert_equal IOS_DEFAULT, props[:ios_url]
      assert_equal GROUP_URL, props[:android_group_url]
      assert_equal ANDROID_OPT_IN_DEFAULT, props[:android_opt_in_url]
    end
  end

  test "to_props carries a nil android_group_url when the group url is unset" do
    with_env("ANDROID_TESTER_GROUP_URL" => nil) do
      assert_nil MobileAppLinks.to_props[:android_group_url]
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
