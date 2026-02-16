class SettingsController < ApplicationController
  include TimeFormatting

  TIMEZONE_OPTIONS = ActiveSupport::TimeZone.us_zones.map { |tz| { value: tz.name, label: tz.to_s } }.freeze

  def show
    render inertia: "Settings/Profile", props: {
      user: serialize_user,
      timezone_options: TIMEZONE_OPTIONS,
      update_path: settings_path,
      password_path: settings_password_path
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
    render inertia: "Settings/OnCall"
  end

  def equipment_types
    authorize_manage_equipment_types!

    org = current_user.organization
    active_types = org.equipment_types.active.order(:name)
    inactive_types = org.equipment_types.where(active: false).order(:name)

    render inertia: "Settings/EquipmentTypes", props: {
      active_types: active_types.map { |t| serialize_equipment_type(t) },
      inactive_types: inactive_types.map { |t| serialize_equipment_type(t) },
      create_path: create_equipment_type_path
    }
  end

  def create_equipment_type
    authorize_manage_equipment_types!

    et = current_user.organization.equipment_types.new(name: params[:name])
    if et.save
      redirect_to equipment_types_settings_path, notice: "Equipment type added."
    else
      redirect_to equipment_types_settings_path,
        inertia: { errors: et.errors.to_hash },
        alert: et.errors.full_messages.join(", ")
    end
  end

  def deactivate_equipment_type
    authorize_manage_equipment_types!

    et = current_user.organization.equipment_types.find(params[:id])
    et.update!(active: false)
    redirect_to equipment_types_settings_path, notice: "#{et.name} deactivated."
  end

  def reactivate_equipment_type
    authorize_manage_equipment_types!

    et = current_user.organization.equipment_types.find(params[:id])
    et.update!(active: true)
    redirect_to equipment_types_settings_path, notice: "#{et.name} reactivated."
  end

  private

  def authorize_manage_equipment_types!
    raise ActiveRecord::RecordNotFound unless current_user.can?(Permissions::MANAGE_EQUIPMENT_TYPES)
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
      organization_name: current_user.organization.name
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
