require "test_helper"

class WellKnownControllerTest < ActionDispatch::IntegrationTest
  test "assetlinks JSON renders public + json content type" do
    get "/.well-known/assetlinks.json"
    assert_response :success
    assert_equal "application/json; charset=utf-8", response.content_type
  end

  test "assetlinks JSON declares the Android package + handle_all_urls relation" do
    get "/.well-known/assetlinks.json"
    body = JSON.parse(response.body)

    assert_equal 1, body.length
    entry = body.first
    assert_equal %w[delegate_permission/common.handle_all_urls], entry["relation"]
    assert_equal "android_app", entry["target"]["namespace"]
    assert_equal "com.genixo.restoration", entry["target"]["package_name"]
    assert_kind_of Array, entry["target"]["sha256_cert_fingerprints"]
  end

  test "assetlinks JSON includes SHA-256 fingerprints from env" do
    with_env("ANDROID_APP_LINKS_SHA256" => "AB:CD:EF, 12:34:56") do
      get "/.well-known/assetlinks.json"
      fingerprints = JSON.parse(response.body).first["target"]["sha256_cert_fingerprints"]
      assert_equal %w[AB:CD:EF 12:34:56], fingerprints
    end
  end

  test "assetlinks JSON returns an empty fingerprint array when env unset" do
    with_env("ANDROID_APP_LINKS_SHA256" => nil) do
      get "/.well-known/assetlinks.json"
      fingerprints = JSON.parse(response.body).first["target"]["sha256_cert_fingerprints"]
      assert_equal [], fingerprints
    end
  end

  private

  def with_env(values)
    originals = values.transform_values { |_| nil }
    values.each_key { |k| originals[k] = ENV[k] }
    values.each { |k, v| ENV[k] = v }
    yield
  ensure
    originals.each { |k, v| ENV[k] = v }
  end
end
