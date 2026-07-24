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
  # datetime is required to map a range response's days back to their dates.
  ELEMENTS = "datetime,tempmax,tempmin,temp,conditions,precip,precipprob,windspeed,humidity".freeze
  TIMEOUT_SECONDS = 5

  def self.for(incident:, date:)
    new(incident: incident, date: date).call
  end

  # Weather for every day in start_date..end_date as a Hash of Date =>
  # WeatherSnapshot (days that could not be fetched are simply absent). Days
  # already cached as final are served from the DB; the remaining span is
  # fetched in ONE Timeline API range request — never a call per day, so a
  # 31-day report costs one HTTP round-trip, not 31 sequential timeouts.
  def self.for_range(incident:, start_date:, end_date:)
    new(incident: incident, date: start_date, end_date: end_date).call_range
  end

  def initialize(incident:, date:, end_date: nil)
    @incident = incident
    @date = date.is_a?(String) ? Date.parse(date) : date
    @end_date = end_date.nil? ? @date : (end_date.is_a?(String) ? Date.parse(end_date) : end_date)
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

  def call_range
    cached = WeatherSnapshot.where(incident_id: @incident.id, date: @date..@end_date).index_by(&:date)
    needed = (@date..@end_date).reject { |day| cached[day] && final?(cached[day]) }
    return cached if needed.empty?

    cached.merge(fetch_and_store_range(needed, cached))
  rescue StandardError => e
    Rails.logger.warn("[WeatherService] range weather unavailable for incident #{@incident.id} #{@date}..#{@end_date}: #{e.class}: #{redact(e.message)}")
    unless e.is_a?(Faraday::Error) || e.is_a?(JSON::ParserError)
      Honeybadger.notify(e) if defined?(Honeybadger)
    end
    cached || {}
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
    day = timeline_days(@date.iso8601, "#{@date}")&.first
    return nil if day.blank?

    # store_snapshot rescues the concurrent-generation race (RecordNotUnique
    # from the DB index, RecordInvalid from the model validation seeing the
    # winner first) by returning the winner's row.
    store_snapshot(day, @date, existing)
  end

  # One Timeline API request for the given date path ("2026-07-01" or
  # "2026-07-01/2026-07-07"). Returns the parsed days array, or nil when the
  # key/address is missing or the API answered non-2xx (logged, never silent —
  # a 401 (bad key) or 429 (quota) must be visible in logs, not just a missing
  # weather line; status only, the key stays out).
  def timeline_days(date_path, log_label)
    return nil if api_key.blank?

    location = location_string
    return nil if location.blank?

    url = "#{BASE_URL}/#{ERB::Util.url_encode(location)}/#{date_path}"
    response = connection.get(url) do |req|
      req.params["key"] = api_key
      req.params["include"] = "days"
      req.params["elements"] = ELEMENTS
      req.params["unitGroup"] = "us"
      req.params["contentType"] = "json"
    end
    unless response.success?
      Rails.logger.warn("[WeatherService] Visual Crossing returned #{response.status} for incident #{@incident.id} #{log_label}")
      return nil
    end

    JSON.parse(response.body)["days"] || []
  end

  # One Timeline API range request covering min(needed)..max(needed). The
  # response includes every day in that span; only the needed (missing or
  # provisional) days are upserted, so a final snapshot in the middle of the
  # span is never overwritten. Returns a Hash of Date => WeatherSnapshot for
  # the days that were stored.
  def fetch_and_store_range(needed, cached)
    days = timeline_days("#{needed.min.iso8601}/#{needed.max.iso8601}", "#{needed.min}..#{needed.max}")
    return {} if days.nil?

    needed_set = needed.to_set
    days.each_with_object({}) do |day, stored|
      day_date = begin
        Date.parse(day["datetime"].to_s)
      rescue ArgumentError, TypeError
        next
      end
      next unless needed_set.include?(day_date)

      snapshot = store_snapshot(day, day_date, cached[day_date])
      stored[day_date] = snapshot if snapshot
    end
  end

  def store_snapshot(day, day_date, existing)
    attrs = snapshot_attrs(day)
    if existing
      existing.update!(attrs)
      existing
    else
      WeatherSnapshot.create!(attrs.merge(incident_id: @incident.id, date: day_date))
    end
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    # A concurrent generation stored this day first — use the winner's row.
    WeatherSnapshot.find_by(incident_id: @incident.id, date: day_date)
  end

  def snapshot_attrs(day)
    {
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
