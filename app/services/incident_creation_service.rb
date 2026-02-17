class IncidentCreationService
  def initialize(property:, user:, params:)
    @property = property
    @user = user
    @params = params
  end

  def call
    ActiveRecord::Base.transaction do
      @incident = create_incident
      auto_transition_status
      auto_assign_users
      assign_additional_users
      create_contacts
      log_creation_events
      # TODO: Phase 5 — EscalationJob.perform_later(@incident) if @incident.emergency?
      # TODO: Phase 5 — IncidentMailer.incident_created(@incident).deliver_later
      @incident
    end
  end

  private

  def create_incident
    Incident.create!(
      property: @property,
      created_by_user: @user,
      status: "new",
      emergency: @params[:project_type] == "emergency_response",
      project_type: @params[:project_type],
      damage_type: @params[:damage_type],
      description: @params[:description],
      cause: @params[:cause],
      requested_next_steps: @params[:requested_next_steps],
      units_affected: @params[:units_affected],
      affected_room_numbers: @params[:affected_room_numbers],
      job_id: @params[:job_id],
      do_not_exceed_limit: @params[:do_not_exceed_limit],
      location_of_damage: @params[:location_of_damage]
    )
  end

  def auto_transition_status
    new_status = case @incident.project_type
    when "emergency_response", "other"
      "acknowledged"
    when "mitigation_rfq", "buildback_rfq", "capex_rfq"
      "quote_requested"
    end

    @incident.update!(status: new_status)
  end

  def auto_assign_users
    users_to_assign = Set.new

    # PM-side: property assignees (property_managers, area_managers on this property)
    @property.assigned_users.active.where(user_type: [User::PROPERTY_MANAGER, User::AREA_MANAGER]).find_each do |u|
      users_to_assign << u
    end

    # PM-side: all pm_managers in the property's PM org
    @property.property_management_org.users.active.where(user_type: User::PM_MANAGER).find_each do |u|
      users_to_assign << u
    end

    # Mitigation-side: managers + office_sales (NOT technicians)
    @property.mitigation_org.users.active.where(user_type: [User::MANAGER, User::OFFICE_SALES]).find_each do |u|
      users_to_assign << u
    end

    users_to_assign.each do |u|
      @incident.incident_assignments.create!(user: u, assigned_by_user: @user)
    end
  end

  def assign_additional_users
    additional_ids = Array(@params[:additional_user_ids]).map(&:to_i).reject(&:zero?)
    return if additional_ids.empty?

    already_assigned = @incident.assigned_user_ids
    additional_ids.each do |user_id|
      next if already_assigned.include?(user_id)

      user = User.find_by(id: user_id, active: true)
      next unless user

      @incident.incident_assignments.create!(user: user, assigned_by_user: @user)
    end
  end

  def create_contacts
    contacts = Array(@params[:contacts]).select { |c| c[:name].present? }
    contacts.each do |contact_data|
      @incident.incident_contacts.create!(
        name: contact_data[:name],
        title: contact_data[:title],
        email: contact_data[:email],
        phone: contact_data[:phone],
        onsite: contact_data[:onsite] || false,
        created_by_user: @user
      )
    end
  end

  def log_creation_events
    ActivityLogger.log(
      incident: @incident, event_type: "incident_created", user: @user,
      metadata: { project_type: @incident.project_type, emergency: @incident.emergency }
    )
    ActivityLogger.log(
      incident: @incident, event_type: "status_changed", user: @user,
      metadata: { old_status: "new", new_status: @incident.status }
    )
  end
end
