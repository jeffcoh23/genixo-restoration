# Single source of truth for the mobile app install links, shared by the
# invitation mailer and the in-app Settings notice.
#
# - iOS is live on the App Store (one tap, public).
# - Android is a closed beta: testers self-join the Google Group, then opt in
#   via the Play link. The Android steps only surface when the group URL is
#   configured (ANDROID_TESTER_GROUP_URL), so they disappear automatically once
#   Android graduates to a public Play Store listing and the env is cleared.
module MobileAppLinks
  module_function

  DEFAULT_IOS_APP_STORE_URL = "https://apps.apple.com/us/app/genixo-restoration/id6760802383".freeze
  DEFAULT_ANDROID_OPT_IN_URL = "https://play.google.com/apps/testing/com.genixo.restoration".freeze

  def ios_app_store_url
    ENV["IOS_APP_STORE_URL"].presence || DEFAULT_IOS_APP_STORE_URL
  end

  # Google Group join URL. nil until configured, which hides the Android steps.
  def android_tester_group_url
    ENV["ANDROID_TESTER_GROUP_URL"].presence
  end

  def android_opt_in_url
    ENV["ANDROID_OPT_IN_URL"].presence || DEFAULT_ANDROID_OPT_IN_URL
  end

  def android_beta?
    android_tester_group_url.present?
  end

  # Shape passed to Inertia pages as the `mobile_app` prop.
  def to_props
    {
      ios_url: ios_app_store_url,
      android_group_url: android_tester_group_url,
      android_opt_in_url: android_opt_in_url
    }
  end
end
