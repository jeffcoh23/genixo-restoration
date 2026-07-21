require "test_helper"
require "webmock/minitest"
require "minitest/mock"

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

  # --- Same-day (provisional) snapshot refresh ---

  test "refreshes a snapshot that was fetched on the report date itself" do
    # Fetched the same day it describes → may hold forecast values, not finals.
    stale = WeatherSnapshot.create!(incident: @incident, date: Date.current,
      temp_max: 75, conditions: "Forecast-ish", fetched_at: Time.current)
    stub = stub_vc

    snap = WeatherService.for(incident: @incident, date: Date.current)

    assert_requested stub, times: 1
    assert_equal stale.id, snap.id, "must update the existing row, not create a duplicate"
    assert_equal "Partly cloudy", snap.reload.conditions
    assert_equal 1, WeatherSnapshot.where(incident: @incident, date: Date.current).count
  end

  test "a snapshot fetched after its date is final — no refetch" do
    # No stub registered: any HTTP attempt would make WebMock raise.
    final = WeatherSnapshot.create!(incident: @incident, date: @date,
      conditions: "Observed", fetched_at: (@date + 1).noon)
    snap = WeatherService.for(incident: @incident, date: @date)
    assert_equal final.id, snap.id
    assert_equal "Observed", snap.conditions
  end

  test "a failed refresh falls back to the stale snapshot instead of nil" do
    stale = WeatherSnapshot.create!(incident: @incident, date: Date.current,
      conditions: "Morning forecast", fetched_at: Time.current)
    stub_request(:get, /weather\.visualcrossing\.com/).to_timeout

    snap = WeatherService.for(incident: @incident, date: Date.current)
    assert_equal stale.id, snap.id, "stale weather beats no weather"
  end

  # --- Concurrency: both duplicate-insert failure modes return the winner ---

  test "returns the winner's row when the model uniqueness validation loses the race" do
    winner = WeatherSnapshot.create!(incident: @incident, date: @date,
      conditions: "Winner", fetched_at: (@date + 1).noon)
    stub_vc

    # Simulate the race: the initial cache check misses (returns nil), but the
    # winner's committed row makes create! raise RecordInvalid via the model's
    # uniqueness validation. The rescue must recover the winner, not return nil.
    calls = 0
    racing_find_by = lambda do |*args, **kwargs|
      calls += 1
      calls == 1 ? nil : winner
    end

    WeatherSnapshot.stub(:find_by, racing_find_by) do
      assert_equal winner.id, WeatherService.for(incident: @incident, date: @date)&.id
    end
  end

  # --- Range fetch (weekly reports) ---

  def range_body(dates)
    {
      "days" => dates.map do |d|
        {
          "datetime" => d.iso8601, "tempmax" => 88.2, "tempmin" => 71.4, "temp" => 79.1,
          "conditions" => "Cloudy #{d.iso8601}", "precip" => 0.1, "precipprob" => 30,
          "windspeed" => 9.3, "humidity" => 65
        }
      end
    }.to_json
  end

  test "for_range fetches the whole span in ONE request and returns a date-keyed hash" do
    start_date = @date
    end_date = @date + 6.days
    stub = stub_vc(body: range_body((start_date..end_date).to_a))

    result = WeatherService.for_range(incident: @incident, start_date: start_date, end_date: end_date)

    assert_requested stub, times: 1
    assert_equal 7, result.size
    assert_equal "Cloudy #{start_date.iso8601}", result[start_date].conditions
    assert_equal "Cloudy #{end_date.iso8601}", result[end_date].conditions
    assert result.values.all?(&:persisted?)
  end

  test "for_range serves final cached days from the DB and only fetches the gap" do
    start_date = @date
    end_date = @date + 2.days
    # Day 1 is final (fetched after its date ended) — must not be re-fetched
    # or overwritten.
    final = WeatherSnapshot.create!(incident: @incident, date: start_date,
      temp_max: 50, conditions: "Final cached", fetched_at: (start_date + 1.day).to_time.change(hour: 6))

    stub = stub_vc(body: range_body([ start_date + 1.day, end_date ]))
    result = WeatherService.for_range(incident: @incident, start_date: start_date, end_date: end_date)

    assert_requested stub, times: 1
    assert_equal 3, result.size
    assert_equal final.id, result[start_date].id
    assert_equal "Final cached", result[start_date].reload.conditions
  end

  test "for_range makes no request when every day is cached final" do
    (@date..@date + 1.day).each do |d|
      WeatherSnapshot.create!(incident: @incident, date: d, temp_max: 60,
        conditions: "Done", fetched_at: (d + 1.day).to_time.change(hour: 6))
    end

    # No stub registered: an HTTP call would raise via WebMock.
    result = WeatherService.for_range(incident: @incident, start_date: @date, end_date: @date + 1.day)
    assert_equal 2, result.size
  end

  test "for_range returns the cached days when the API fails" do
    cached = WeatherSnapshot.create!(incident: @incident, date: @date, temp_max: 60,
      conditions: "Cached", fetched_at: (@date + 1.day).to_time.change(hour: 6))
    stub_vc(status: 500, body: "boom")

    result = WeatherService.for_range(incident: @incident, start_date: @date, end_date: @date + 3.days)

    assert_equal({ @date => cached }, result.transform_values(&:itself).slice(@date))
    assert_equal 1, result.size, "only the cached day should be present after an API failure"
  end

  test "for_range returns an empty hash when the API key is absent and nothing is cached" do
    ENV.delete("VISUAL_CROSSING_API_KEY")
    result = WeatherService.for_range(incident: @incident, start_date: @date, end_date: @date + 2.days)
    assert_equal({}, result)
    assert_equal 0, WeatherSnapshot.count
  end

  test "for_range ignores response days outside the needed set" do
    # API padding/misalignment: a day we already hold as final must not be
    # clobbered even if the response includes it.
    final = WeatherSnapshot.create!(incident: @incident, date: @date, temp_max: 50,
      conditions: "Final cached", fetched_at: (@date + 1.day).to_time.change(hour: 6))
    stub_vc(body: range_body([ @date, @date + 1.day ]))

    result = WeatherService.for_range(incident: @incident, start_date: @date, end_date: @date + 1.day)

    assert_equal "Final cached", final.reload.conditions
    assert_equal "Cloudy #{(@date + 1.day).iso8601}", result[@date + 1.day].conditions
  end

  # --- Operational visibility ---

  test "logs the HTTP status on a non-2xx response" do
    stub_vc(status: 401, body: "No API token found")
    logged = []
    Rails.logger.stub(:warn, ->(msg) { logged << msg }) do
      assert_nil WeatherService.for(incident: @incident, date: @date)
    end
    assert logged.any? { |m| m.include?("401") }, "a bad key / quota failure must be visible in logs, got: #{logged.inspect}"
  end

  test "redacts the API key from logged error messages" do
    stub_request(:get, /weather\.visualcrossing\.com/)
      .to_raise(Faraday::ConnectionFailed.new("connection refused for /timeline?key=test-key&include=days"))
    logged = []
    Rails.logger.stub(:warn, ->(msg) { logged << msg }) do
      assert_nil WeatherService.for(incident: @incident, date: @date)
    end
    refute logged.join.include?("test-key"), "the API key must never reach the logs"
    assert logged.join.include?("[REDACTED]")
  end
end
