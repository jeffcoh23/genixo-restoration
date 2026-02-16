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
end
