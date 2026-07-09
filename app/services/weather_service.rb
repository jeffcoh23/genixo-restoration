require "erb"
require "faraday"

# Fetches the day's weather for an incident's property from the Visual Crossing
# Timeline API and caches it in a WeatherSnapshot. Visual Crossing resolves a
# plain address string and its local timezone, so no geocoding is needed.
#
# Every failure path (no API key, no usable address, HTTP/timeout/parse error)
# returns nil — weather is a nice-to-have on the DFR and must never block or
# fail report generation. Failures are NOT cached, so a later regeneration
# retries.
class WeatherService
  BASE_URL = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline".freeze
  ELEMENTS = "tempmax,tempmin,temp,conditions,precip,precipprob,windspeed,humidity".freeze
  TIMEOUT_SECONDS = 5

  def self.for(incident:, date:)
    new(incident: incident, date: date).call
  end

  def initialize(incident:, date:)
    @incident = incident
    @date = date.is_a?(String) ? Date.parse(date) : date
  end

  def call
    cached = WeatherSnapshot.find_by(incident_id: @incident.id, date: @date)
    return cached if cached

    fetch_and_store
  rescue StandardError => e
    Rails.logger.warn("[WeatherService] weather unavailable for incident #{@incident.id} #{@date}: #{e.class}: #{e.message}")
    nil
  end

  private

  def fetch_and_store
    return nil if api_key.blank?

    location = location_string
    return nil if location.blank?

    url = "#{BASE_URL}/#{ERB::Util.url_encode(location)}/#{@date.iso8601}"
    response = connection.get(url) do |req|
      req.params["key"] = api_key
      req.params["include"] = "days"
      req.params["elements"] = ELEMENTS
      req.params["unitGroup"] = "us"
      req.params["contentType"] = "json"
    end
    return nil unless response.success?

    day = JSON.parse(response.body).dig("days", 0)
    return nil if day.blank?

    WeatherSnapshot.create!(
      incident_id: @incident.id,
      date: @date,
      temp_max: day["tempmax"],
      temp_min: day["tempmin"],
      temp_avg: day["temp"],
      conditions: day["conditions"],
      precip: day["precip"],
      precip_probability: day["precipprob"],
      wind_speed: day["windspeed"],
      humidity: day["humidity"],
      fetched_at: Time.current
    )
  rescue ActiveRecord::RecordNotUnique
    # A concurrent generation stored it first — use the winner's row.
    WeatherSnapshot.find_by(incident_id: @incident.id, date: @date)
  end

  def connection
    @connection ||= Faraday.new do |f|
      f.options.timeout = TIMEOUT_SECONDS
      f.options.open_timeout = TIMEOUT_SECONDS
    end
  end

  # Visual Crossing geocodes a free-text address; require at least a city or ZIP
  # so we don't waste a call (or return a wrong location) on a bare street line.
  def location_string
    property = @incident.property
    return nil unless property
    return nil unless property.city.present? || property.zip.present?

    [ property.street_address, property.city, property.state, property.zip ]
      .map { |part| part.to_s.strip }
      .reject(&:blank?)
      .join(", ")
  end

  def api_key
    ENV["VISUAL_CROSSING_API_KEY"]
  end
end
