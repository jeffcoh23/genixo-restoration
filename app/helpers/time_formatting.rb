module TimeFormatting
  def format_date(date)
    return nil unless date
    date.strftime("%b %-d, %Y")
  end

  def format_time(time)
    return nil unless time
    time.strftime("%-I:%M %p")
  end

  def format_datetime(time)
    return nil unless time
    time.strftime("%b %-d, %Y %-I:%M %p")
  end

  def format_time_value(time)
    return nil unless time
    time.strftime("%H:%M")
  end

  def format_datetime_value(time)
    return nil unless time
    time.strftime("%Y-%m-%dT%H:%M")
  end

  def format_relative_time(time)
    return nil unless time

    seconds = (Time.current - time).to_i
    return "just now" if seconds < 60

    minutes = seconds / 60
    return "#{minutes}m ago" if minutes < 60

    hours = minutes / 60
    return "#{hours}h ago" if hours < 24

    days = hours / 24
    "#{days}d ago"
  end
end
