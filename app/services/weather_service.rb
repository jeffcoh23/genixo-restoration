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
#
# Caching: a snapshot fetched on the report date itself may hold provisional
# forecast values (a DFR is usually generated the same day). Such a snapshot is
# refreshed on the next generation after the day has ended; once a fetch lands
# after its date, the row is final and never re-fetched. If a refresh attempt
# fails, the stale snapshot is returned rather than nothing.
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
    return cached if cached && final?(cached)

    fetch_and_store(cached) || cached
  rescue StandardError => e
    Rails.logger.warn("[WeatherService] weather unavailable for incident #{@incident.id} #{@date}: #{e.class}: #{redact(e.message)}")
    # Timeouts/HTTP/parse failures are expected transients; anything else is a
    # bug worth surfacing (matches NotificationService's swallow-but-notify).
    unless e.is_a?(Faraday::Error) || e.is_a?(JSON::ParserError)
      Honeybadger.notify(e) if defined?(Honeybadger)
    end
    cached
  end

  private

  # A snapshot holds final (observed) data once it was fetched after its date
  # ended. fetched_at is UTC; for US-continent properties the UTC day flips a
  # few hours early, which at worst treats a late-evening fetch as final —
  # acceptable next to the flaw this guards against (a morning forecast being
  # cached forever).
  def final?(snapshot)
    snapshot.fetched_at.to_date > snapshot.date
  end

  def fetch_and_store(existing = nil)
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
    unless response.success?
      # Never silent: a 401 (bad key) or 429 (quota) must be visible in logs,
      # not just a missing weather line. Status only — the key stays out.
      Rails.logger.warn("[WeatherService] Visual Crossing returned #{response.status} for incident #{@incident.id} #{@date}")
      return nil
    end

    day = JSON.parse(response.body).dig("days", 0)
    return nil if day.blank?

    attrs = {
      temp_max: day["tempmax"],
      temp_min: day["tempmin"],
      temp_avg: day["temp"],
      conditions: day["conditions"],
      precip: day["precip"],
      precip_probability: day["precipprob"],
      wind_speed: day["windspeed"],
      humidity: day["humidity"],
      fetched_at: Time.current
    }

    if existing
      existing.update!(attrs)
      existing
    else
      WeatherSnapshot.create!(attrs.merge(incident_id: @incident.id, date: @date))
    end
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    # A concurrent generation stored it first — use the winner's row. The race
    # surfaces two ways: the DB unique index (RecordNotUnique) or the model's
    # uniqueness validation seeing the winner just before our INSERT
    # (RecordInvalid). Both mean the same thing.
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

  # The API key travels as a query param, so a rare Faraday error that echoes the
  # request URL could carry it into logs/Honeybadger. Scrub it defensively.
  def redact(text)
    key = api_key
    key.present? ? text.to_s.gsub(key, "[REDACTED]") : text.to_s
  end
end
