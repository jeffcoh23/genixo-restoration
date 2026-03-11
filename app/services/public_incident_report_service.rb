class PublicIncidentReportService
  attr_reader :errors

  REQUIRED_FIELDS = %w[reporter_email reporter_name reporter_phone property_description project_type damage_type description].freeze

  def initialize(params)
    @params = params.to_h.with_indifferent_access
    @errors = {}
  end

  def call
    return false unless valid?

    recipients = resolve_recipients
    if recipients.empty?
      Rails.logger.warn("[PublicIncidentReport] No recipients found for report from #{@params[:reporter_email]}")
      return true # Don't expose internal state to the reporter
    end

    send_notifications(recipients)
    true
  end

  private

  def valid?
    REQUIRED_FIELDS.each do |field|
      @errors[field] = "can't be blank" if @params[field].blank?
    end

    if @params["reporter_email"].present? && !@params["reporter_email"].match?(URI::MailTo::EMAIL_REGEXP)
      @errors["reporter_email"] = "is not a valid email address"
    end

    if @params["project_type"].present? && !Incident::PROJECT_TYPES.include?(@params["project_type"])
      @errors["project_type"] = "is not valid"
    end

    if @params["damage_type"].present? && !Incident::DAMAGE_TYPES.include?(@params["damage_type"])
      @errors["damage_type"] = "is not valid"
    end

    @errors.empty?
  end

  def resolve_recipients
    mit_org = Organization.find_by(organization_type: "mitigation")
    return [] unless mit_org

    recipients = Set.new

    # Auto-assign users
    mit_org.users.active.auto_assigned.each { |u| recipients << u }

    # On-call primary user
    config = mit_org.on_call_configuration
    recipients << config.primary_user if config&.primary_user&.active?

    # Fallback: all active managers
    if recipients.empty?
      mit_org.users.active.where(user_type: User::MANAGER).each { |u| recipients << u }
    end

    recipients.to_a
  end

  def send_notifications(recipients)
    recipients.each do |user|
      IncidentMailer.public_report_received(user, report_data, emergency?).deliver_later
    end

    send_emergency_notifications if emergency?
  end

  def send_emergency_notifications
    mit_org = Organization.find_by(organization_type: "mitigation")
    return unless mit_org

    config = mit_org.on_call_configuration
    return unless config

    contacts = [config.primary_user] + config.escalation_contacts.order(:position).map(&:user)
    contacts.compact.each do |user|
      next unless user.phone.present?
      NotificationService.send_sms(
        to: user.phone,
        message: "EMERGENCY public incident report: #{@params[:property_description].to_s.truncate(80)}. " \
                 "Damage: #{Incident::DAMAGE_LABELS[@params[:damage_type]]}. " \
                 "Reporter: #{@params[:reporter_name]} #{@params[:reporter_email]}"
      )
    end
  end

  def emergency?
    @params[:emergency] == "1" || @params[:emergency] == true || @params[:emergency] == "true"
  end

  def report_data
    @params.slice(
      :reporter_email, :reporter_name, :reporter_phone,
      :property_description, :project_type, :damage_type,
      :description, :emergency
    )
  end
end
