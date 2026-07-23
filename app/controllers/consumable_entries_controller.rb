class ConsumableEntriesController < ApplicationController
  before_action :set_incident
  before_action :authorize_consumables!

  # Saves one day's consumables sheet in a single request: the submitted rows
  # REPLACE that date's entries (the UI shows the full prefilled list, so what
  # comes back is the whole sheet — zero/blank rows simply aren't stored).
  def create
    log_date = parse_iso_date(params[:log_date])
    return redirect_to incident_path(@incident), alert: "Could not save consumables: invalid date." if log_date.nil?

    rows = Array(params[:entries]).filter_map { |row| build_row(row, log_date) }

    ConsumableEntry.transaction do
      # Serialize concurrent saves per incident: without the lock, two
      # replace-day transactions can interleave delete/insert and double the
      # day's rows — and PDF billing totals sum every row.
      @incident.lock!
      # Entries of deactivated types are invisible in the sheet (it only
      # renders active types), so they must survive a replace — deleting them
      # here would be silent data loss the user can't see or prevent.
      active_type_ids = @incident.property.mitigation_org.consumable_types.active.pluck(:id)
      @incident.consumable_entries.for_date(log_date)
        .where(consumable_type_id: [ nil ] + active_type_ids)
        .destroy_all
      rows.each(&:save!)
    end

    ActivityLogger.log(
      incident: @incident,
      event_type: "consumables_logged",
      user: current_user,
      metadata: { log_date: log_date.iso8601, count: rows.size }
    )

    redirect_to incident_path(@incident), notice: "Consumables saved."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to incident_path(@incident),
      inertia: { errors: e.record.errors.to_hash },
      alert: "Could not save consumables."
  end

  private

  def build_row(row, log_date)
    # A crafted payload can put scalars in the entries array — drop them
    # instead of 500ing on row.permit.
    return nil unless row.respond_to?(:permit)

    permitted = row.permit(:consumable_type_id, :custom_name, :quantity)
    quantity = Integer(permitted[:quantity], exception: false)
    return nil if quantity.nil? || quantity <= 0
    # Above the model's cap: keep the row and let validation reject it with a
    # proper inline error instead of a cast-time RangeError 500.
    quantity = [ quantity, ConsumableEntry::MAX_QUANTITY + 1 ].min

    type_id = permitted[:consumable_type_id].presence
    custom_name = permitted[:custom_name].to_s.strip.presence
    return nil if type_id.nil? && custom_name.nil?

    # Scope the type to the incident's mitigation org so a foreign org's type
    # ID can never be attached to this incident.
    consumable_type = type_id && @incident.property.mitigation_org.consumable_types.find(type_id)

    @incident.consumable_entries.new(
      consumable_type: consumable_type,
      custom_name: consumable_type ? nil : custom_name,
      quantity: quantity,
      log_date: log_date,
      logged_by_user: current_user
    )
  end

  def set_incident
    @incident = find_visible_incident!(params[:incident_id])
  end

  def authorize_consumables!
    raise ActiveRecord::RecordNotFound unless current_user.can?(Permissions::MANAGE_DAILY_LOGS)
  end
end
