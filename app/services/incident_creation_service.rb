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
      assign_users
      invite_guests
      create_contacts
      log_creation_events
      send_notifications
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
    new_status = if @incident.quote?
      "proposal_requested"
    else
      "acknowledged"
    end

    @incident.update!(status: new_status)
  end

  def assign_users
    users_to_assign = default_auto_assign_users

    # When the UI sends assignment selections, treat them as the full selected set
    # (auto + manually checked), not just "additional" users — but only for the
    # users this creator can actually see/select in the UI. Hidden auto-assigns
    # (e.g., mitigation-side managers when a PM user creates an incident) are preserved.
    if @params.key?(:additional_user_ids)
      selected_ids = Array(@params[:additional_user_ids]).map(&:to_i).reject(&:zero?)
      selectable_ids = selectable_user_ids_for_creator
      preserved_default_users = users_to_assign.reject { |u| selectable_ids.include?(u.id) }
      selected_users = User.where(id: selected_ids & selectable_ids, active: true).to_a
      users_to_assign = preserved_default_users.to_set.merge(selected_users)
    end

    users_to_assign.each do |u|
      @incident.incident_assignments.create!(user: u, assigned_by_user: @user)
    end
  end

  def default_auto_assign_users
    users_to_assign = Set.new

    # Mitigation-side: users with auto_assign flag
    @property.mitigation_org.users.active.auto_assigned.find_each do |u|
      users_to_assign << u
    end

    # Mitigation-side: always include on-call primary user
    on_call_config = @property.mitigation_org.on_call_configuration
    if on_call_config&.primary_user&.active?
      users_to_assign << on_call_config.primary_user
    end

    # Fallback: if no auto-assign users and no on-call, assign all active mitigation managers
    if users_to_assign.empty?
      @property.mitigation_org.users.active.where(user_type: User::MANAGER).find_each do |u|
        users_to_assign << u
      end
    end

    # PM-side: nobody — PM creator picks manually
    users_to_assign
  end

  def selectable_user_ids_for_creator
    org_ids = if @user.pm_user?
      [ @property.property_management_org_id ]
    else
      [ @property.mitigation_org_id, @property.property_management_org_id ]
    end

    User.where(active: true, organization_id: org_ids).pluck(:id)
  end

  def invite_guests
    guests = Array(@params[:guests]).select { |g| g[:email].present? }
    return if guests.empty?

    external_org = Organization.find_by(organization_type: "external")
    return unless external_org

    guests.each do |guest_data|
      email = guest_data[:email].strip.downcase
      user = User.find_by(email_address: email)
      next if user && !user.guest? # Skip non-guest existing users

      if user.nil?
        user = external_org.users.create!(
          email_address: email,
          first_name: guest_data[:first_name],
          last_name: guest_data[:last_name],
          title: guest_data[:title].presence,
          user_type: User::GUEST,
          password: SecureRandom.hex(20),
          active: false
        )

        invitation = external_org.invitations.create!(
          invited_by_user: @user,
          email: email,
          user_type: User::GUEST,
          first_name: user.first_name,
          last_name: user.last_name,
          title: user.title,
          permissions: [],
          expires_at: 30.days.from_now
        )
        InvitationMailer.invite(invitation).deliver_later
      elsif !user.active?
        # Resend invitation for inactive guest
        invitation = user.organization.invitations.where(email: email, accepted_at: nil).first
        if invitation
          invitation.update!(token: SecureRandom.urlsafe_base64(32), expires_at: 30.days.from_now)
          InvitationMailer.invite(invitation).deliver_later
        end
      end

      assignment = @incident.incident_assignments.find_or_create_by!(user: user) do |a|
        a.assigned_by_user = @user
      end

      if assignment.previously_new_record?
        ActivityLogger.log(
          incident: @incident, event_type: "user_assigned", user: @user,
          metadata: { assigned_user_id: user.id, assigned_user_name: user.full_name }
        )
        AssignmentNotificationJob.perform_later(assignment.id) if user.active?
      end
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

  def send_notifications
    if @user.notification_preference("incident_user_assignment")
      IncidentMailer.creation_confirmation(@incident).deliver_later
    end

    @incident.incident_assignments.each do |assignment|
      next if assignment.user_id == @user.id
      AssignmentNotificationJob.perform_later(assignment.id)
    end

    EscalationJob.perform_later(@incident.id) if @incident.emergency?
  end
end
