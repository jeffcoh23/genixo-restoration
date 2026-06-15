class WellKnownController < ApplicationController
  allow_unauthenticated_access

  # Android App Links — Google's verifier hits /.well-known/assetlinks.json
  # to confirm this domain authorizes the Android app to handle its https links.
  #
  # SHA-256 fingerprints come from:
  #   1) The local upload keystore (`mobile/android/keystore/genixo-upload.jks`)
  #      — used while building locally before Play App Signing kicks in.
  #   2) Google Play's app signing key (visible in Play Console once the first
  #      AAB is uploaded: Setup → App integrity → App signing key certificate).
  #
  # Both fingerprints must be listed once Play App Signing is active, because
  # production builds shipped via Play are re-signed with Google's key.
  def assetlinks
    render json: [
      {
        relation: %w[delegate_permission/common.handle_all_urls],
        target: {
          namespace: "android_app",
          package_name: "com.genixo.restoration",
          sha256_cert_fingerprints: android_sha256_fingerprints
        }
      }
    ]
  end

  private

  def android_sha256_fingerprints
    ENV.fetch("ANDROID_APP_LINKS_SHA256", "").split(",").map(&:strip).reject(&:blank?)
  end
end
