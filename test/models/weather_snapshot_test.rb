require "test_helper"

class WeatherSnapshotTest < ActiveSupport::TestCase
  def build_snapshot(**attrs)
    WeatherSnapshot.new({ date: Date.current, fetched_at: Time.current }.merge(attrs))
  end

  test "summary_line formats hi/lo temps, conditions, precip, and wind" do
    s = build_snapshot(temp_max: 88, temp_min: 71, conditions: "Partly cloudy", precip: 0.12, wind_speed: 9)
    assert_equal "88°F / 71°F  ·  Partly cloudy  ·  0.12 in precip  ·  wind 9 mph", s.summary_line
  end

  test "summary_line omits precip when zero" do
    s = build_snapshot(temp_max: 80, temp_min: 60, conditions: "Clear", precip: 0, wind_speed: 5)
    assert_equal "80°F / 60°F  ·  Clear  ·  wind 5 mph", s.summary_line
  end

  test "summary_line falls back to the average temp when hi/lo are missing" do
    s = build_snapshot(temp_avg: 75, conditions: "Cloudy")
    assert_equal "75°F  ·  Cloudy", s.summary_line
  end

  test "summary_line rounds fractional temps and wind" do
    s = build_snapshot(temp_max: 88.2, temp_min: 71.4, conditions: "Rain", precip: 0.5, wind_speed: 9.3)
    assert_equal "88°F / 71°F  ·  Rain  ·  0.5 in precip  ·  wind 9 mph", s.summary_line
  end

  test "summary_line is nil when there is nothing worth printing" do
    assert_nil build_snapshot.summary_line
  end
end
