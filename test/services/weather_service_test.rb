require "test_helper"
require "webmock/minitest"

class WeatherServiceTest < ActiveSupport::TestCase
  setup do
    ENV["VISUAL_CROSSING_API_KEY"] = "test-key"
    WebMock.disable_net_connect!(allow_localhost: true)

    genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @property = Property.create!(name: "Sunset Apts", mitigation_org: genixo, property_management_org: greystar,
      street_address: "2200 Willowick Rd", city: "Houston", state: "TX", zip: "77027")
    manager = User.create!(organization: genixo, user_type: "manager",
      email_address: "wx-mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @incident = Incident.create!(property: @property, created_by_user: manager,
      status: "active", project_type: "emergency_response", damage_type: "flood", description: "Wx")
    @date = Date.new(2026, 7, 3)
  end

  teardown do
    ENV.delete("VISUAL_CROSSING_API_KEY")
    WebMock.reset!
    WebMock.allow_net_connect!
  end

  def default_body
    {
      "days" => [ {
        "tempmax" => 88.2, "tempmin" => 71.4, "temp" => 79.1,
        "conditions" => "Partly cloudy", "precip" => 0.12, "precipprob" => 30,
        "windspeed" => 9.3, "humidity" => 65
      } ]
    }.to_json
  end

  def stub_vc(status: 200, body: nil)
    stub_request(:get, /weather\.visualcrossing\.com/)
      .to_return(status: status, body: body || default_body, headers: { "Content-Type" => "application/json" })
  end

  test "fetches, parses, and caches a weather snapshot" do
    stub = stub_vc
    snap = WeatherService.for(incident: @incident, date: @date)

    assert snap.persisted?
    assert_equal @date, snap.date
    assert_equal 88.2, snap.temp_max.to_f
    assert_equal 71.4, snap.temp_min.to_f
    assert_equal "Partly cloudy", snap.conditions
    assert_in_delta 0.12, snap.precip.to_f, 0.001
    assert_equal 9.3, snap.wind_speed.to_f
    assert_requested stub, times: 1
  end

  test "returns the cached snapshot without a second HTTP call" do
    stub = stub_vc
    first = WeatherService.for(incident: @incident, date: @date)
    second = WeatherService.for(incident: @incident, date: @date)

    assert_equal first.id, second.id
    assert_requested stub, times: 1
    assert_equal 1, WeatherSnapshot.where(incident: @incident, date: @date).count
  end

  test "sends the api key, US units, and days-only include" do
    stub = stub_request(:get, /weather\.visualcrossing\.com/)
      .with(query: hash_including("key" => "test-key", "unitGroup" => "us", "include" => "days"))
      .to_return(status: 200, body: default_body, headers: { "Content-Type" => "application/json" })

    WeatherService.for(incident: @incident, date: @date)
    assert_requested stub
  end

  test "returns nil and makes no call when the API key is absent" do
    ENV.delete("VISUAL_CROSSING_API_KEY")
    # No stub registered: if it tried to call out, WebMock would raise.
    assert_nil WeatherService.for(incident: @incident, date: @date)
    assert_equal 0, WeatherSnapshot.count
  end

  test "returns nil and makes no call when the property has no city or zip" do
    @property.update!(city: nil, zip: nil, street_address: "2200 Willowick Rd")
    assert_nil WeatherService.for(incident: @incident, date: @date)
    assert_equal 0, WeatherSnapshot.count
  end

  test "returns nil on an unresolved address (HTTP 400) and caches nothing" do
    stub_vc(status: 400, body: "Bad API Request: Invalid location")
    assert_nil WeatherService.for(incident: @incident, date: @date)
    assert_equal 0, WeatherSnapshot.count
  end

  test "returns nil on a timeout without raising" do
    stub_request(:get, /weather\.visualcrossing\.com/).to_timeout
    assert_nil WeatherService.for(incident: @incident, date: @date)
    assert_equal 0, WeatherSnapshot.count
  end

  test "returns nil when the response has no days" do
    stub_vc(body: { "days" => [] }.to_json)
    assert_nil WeatherService.for(incident: @incident, date: @date)
    assert_equal 0, WeatherSnapshot.count
  end

  test "returns nil on a malformed (non-JSON) 200 body without raising" do
    stub_vc(body: "<html>upstream error</html>")
    assert_nil WeatherService.for(incident: @incident, date: @date)
    assert_equal 0, WeatherSnapshot.count
  end
end
