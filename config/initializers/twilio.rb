if ENV["TWILIO_ACCOUNT_SID"].present? && ENV["TWILIO_AUTH_TOKEN"].present?
  TwilioClient = Twilio::REST::Client.new(
    ENV["TWILIO_ACCOUNT_SID"],
    ENV["TWILIO_AUTH_TOKEN"]
  )
end
