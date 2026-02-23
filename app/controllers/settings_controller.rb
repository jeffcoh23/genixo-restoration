class SettingsController < ApplicationController
  include TimeFormatting

  TIMEZONE_OPTIONS = ActiveSupport::TimeZone.us_zones.map { |tz| { value: tz.name, label: tz.to_s } }.freeze

  def show
    render inertia: "Settings/Profile", props: {
      user: serialize_user,
      timezone_options: TIMEZONE_OPTIONS,
      update_path: settings_path,
      password_path: settings_password_path,
      preferences_path: settings_preferences_path
    }
  end

  def update
    if current_user.update(profile_params)
      redirect_to settings_path, notice: "Profile updated."
    else
      redirect_to settings_path,
        inertia: { errors: current_user.errors.to_hash },
        alert: "Could not update profile."
    end
  end

  def update_password
    unless current_user.authenticate(params[:current_password])
      redirect_to settings_path,
        inertia: { errors: { current_password: "is incorrect" } },
        alert: "Current password is incorrect."
      return
    end

    if params[:password].blank?
      redirect_to settings_path,
        inertia: { errors: { password: "can't be blank" } },
        alert: "New password can't be blank."
      return
    end

    if params[:password] != params[:password_confirmation]
      redirect_to settings_path,
        inertia: { errors: { password_confirmation: "doesn't match" } },
        alert: "Password confirmation doesn't match."
      return
    end

    current_user.update!(password: params[:password])
    redirect_to settings_path, notice: "Password updated."
  end

  def on_call
    authorize_manage_on_call!

    org = current_user.organization
    config = org.on_call_configuration
    managers = org.users.active.where(user_type: [ User::MANAGER, User::OFFICE_SALES ]).order(:last_name, :first_name)

    existing_contact_ids = config ? config.escalation_contacts.pluck(:user_id) : []
    available_escalation = managers.where.not(id: existing_contact_ids)

    render inertia: "Settings/OnCall", props: {
      config: config ? serialize_on_call_config(config) : nil,
      managers: managers.map { |u| { id: u.id, full_name: u.full_name, role_label: User::ROLE_LABELS[u.user_type] } },
      available_escalation_managers: available_escalation.map { |u| { id: u.id, full_name: u.full_name, role_label: User::ROLE_LABELS[u.user_type] } },
      update_path: update_on_call_settings_path,
      contacts_path: escalation_contacts_path,
      reorder_path: reorder_escalation_contacts_path
    }
  end

  def update_on_call
    authorize_manage_on_call!

    org = current_user.organization
    config = org.on_call_configuration || org.build_on_call_configuration

    config.assign_attributes(
      primary_user_id: params[:primary_user_id],
      escalation_timeout_minutes: params[:escalation_timeout_minutes]
    )

    if config.save
      redirect_to on_call_settings_path, notice: "On-call configuration saved."
    else
      redirect_to on_call_settings_path,
        inertia: { errors: config.errors.to_hash },
        alert: config.errors.full_messages.join(", ")
    end
  end

  def create_escalation_contact
    authorize_manage_on_call!

    config = current_user.organization.on_call_configuration
    raise ActiveRecord::RecordNotFound unless config

    next_position = (config.escalation_contacts.maximum(:position) || 0) + 1

    contact = config.escalation_contacts.new(
      user_id: params[:user_id],
      position: next_position
    )

    if contact.save
      redirect_to on_call_settings_path, notice: "Escalation contact added."
    else
      redirect_to on_call_settings_path, alert: contact.errors.full_messages.join(", ")
    end
  end

  def destroy_escalation_contact
    authorize_manage_on_call!

    config = current_user.organization.on_call_configuration
    raise ActiveRecord::RecordNotFound unless config

    contact = config.escalation_contacts.find(params[:id])
    contact.destroy!

    # Reorder remaining contacts
    config.escalation_contacts.order(:position).each_with_index do |c, idx|
      c.update_column(:position, idx + 1)
    end

    redirect_to on_call_settings_path, notice: "Escalation contact removed."
  end

  def reorder_escalation_contacts
    authorize_manage_on_call!

    config = current_user.organization.on_call_configuration
    raise ActiveRecord::RecordNotFound unless config

    contact_ids = Array(params[:contact_ids]).map(&:to_i)
    config_contact_ids = config.escalation_contacts.pluck(:id).sort

    if contact_ids.sort != config_contact_ids
      redirect_to on_call_settings_path, alert: "Invalid contact list."
      return
    end

    # Two-pass update to avoid unique constraint violations on position
    ActiveRecord::Base.transaction do
      contact_ids.each_with_index do |id, idx|
        config.escalation_contacts.where(id: id).update_all(position: -(idx + 1))
      end
      contact_ids.each_with_index do |id, idx|
        config.escalation_contacts.where(id: id).update_all(position: idx + 1)
      end
    end

    redirect_to on_call_settings_path, notice: "Escalation order updated."
  end

  def update_preferences
    prefs = current_user.notification_preferences.merge(
      "status_change" => params[:status_change] == "true" || params[:status_change] == true,
      "new_message" => params[:new_message] == "true" || params[:new_message] == true,
      "daily_digest" => params[:daily_digest] == "true" || params[:daily_digest] == true,
      "incident_creation" => params[:incident_creation] == "true" || params[:incident_creation] == true,
      "user_assignment" => params[:user_assignment] == "true" || params[:user_assignment] == true
    )
    current_user.update!(notification_preferences: prefs)
    redirect_to settings_path, notice: "Notification preferences saved."
  end

  def equipment_types
    redirect_to equipment_items_path
  end

  def create_equipment_type
    authorize_manage_equipment_types!

    et = current_user.organization.equipment_types.new(name: params[:name])
    if et.save
      redirect_to equipment_items_path, notice: "Equipment type added."
    else
      redirect_to equipment_items_path,
        inertia: { errors: et.errors.to_hash },
        alert: et.errors.full_messages.join(", ")
    end
  end

  def deactivate_equipment_type
    authorize_manage_equipment_types!

    et = current_user.organization.equipment_types.find(params[:id])
    et.update!(active: false)
    redirect_to equipment_items_path, notice: "#{et.name} deactivated."
  end

  def reactivate_equipment_type
    authorize_manage_equipment_types!

    et = current_user.organization.equipment_types.find(params[:id])
    et.update!(active: true)
    redirect_to equipment_items_path, notice: "#{et.name} reactivated."
  end

  private

  def authorize_manage_on_call!
    raise ActiveRecord::RecordNotFound unless can_manage_on_call?
  end

  def authorize_manage_equipment_types!
    raise ActiveRecord::RecordNotFound unless can_manage_equipment_types?
  end

  def profile_params
    params.permit(:first_name, :last_name, :email_address, :timezone)
  end

  def serialize_user
    {
      first_name: current_user.first_name,
      last_name: current_user.last_name,
      email_address: current_user.email_address,
      timezone: current_user.timezone,
      role_label: User::ROLE_LABELS[current_user.user_type],
      organization_name: current_user.organization.name,
      notification_preferences: {
        status_change: current_user.notification_preference("status_change"),
        new_message: current_user.notification_preference("new_message"),
        daily_digest: current_user.notification_preference("daily_digest"),
        incident_creation: current_user.notification_preference("incident_creation"),
        user_assignment: current_user.notification_preference("user_assignment")
      }
    }
  end

  def serialize_on_call_config(config)
    {
      primary_user_id: config.primary_user_id,
      escalation_timeout_minutes: config.escalation_timeout_minutes,
      contacts: config.escalation_contacts.includes(:user).map { |c|
        {
          id: c.id,
          user_id: c.user_id,
          full_name: c.user.full_name,
          role_label: User::ROLE_LABELS[c.user.user_type],
          position: c.position,
          remove_path: escalation_contact_path(c)
        }
      }
    }
  end

  def serialize_equipment_type(et)
    {
      id: et.id,
      name: et.name,
      active: et.active,
      deactivate_path: et.active ? deactivate_equipment_type_path(et) : nil,
      reactivate_path: et.active ? nil : reactivate_equipment_type_path(et)
    }
  end
end
