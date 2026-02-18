class NotificationService
  def self.send_sms(to:, message:)
    Rails.logger.info("[NotificationService] SMS to #{to}: #{message}")
  end

  def self.send_voice(to:, message:)
    Rails.logger.info("[NotificationService] Voice to #{to}: #{message}")
  end
end
