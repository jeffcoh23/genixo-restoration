class NotificationService
  def self.send_sms(to:, message:)
    Rails.logger.info("[NotificationService] SMS to #{to}: #{message}")
  end

  def self.send_voice(to:, message:)
    phone = normalize_phone(to)

    unless twilio_configured?
      Rails.logger.info("[NotificationService] Voice call to #{phone}: #{message}")
      return
    end

    twiml = "<Response><Say voice=\"Polly.Joanna\">#{message}</Say><Pause length=\"1\"/><Say voice=\"Polly.Joanna\">#{message}</Say></Response>"

    TwilioClient.calls.create(
      to: phone,
      from: ENV["TWILIO_PHONE_NUMBER"],
      twiml: twiml
    )

    Rails.logger.info("[NotificationService] Voice call initiated to #{phone}")
  rescue => e
    Rails.logger.error("[NotificationService] Voice call failed to #{phone}: #{e.message}")
    Honeybadger.notify(e) if defined?(Honeybadger)
  end

  def self.twilio_configured?
    defined?(TwilioClient) && ENV["TWILIO_PHONE_NUMBER"].present?
  end

  def self.normalize_phone(phone)
    digits = phone.to_s.gsub(/\D/, "")
    digits = "1#{digits}" if digits.length == 10
    "+#{digits}"
  end

  private_class_method :twilio_configured?, :normalize_phone
end
