require "test_helper"

class ConsumableEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @property = Property.create!(name: "Sunset Apts", mitigation_org: @genixo, property_management_org: @greystar)
    @manager = User.create!(organization: @genixo, user_type: "manager", auto_assign: true,
      email_address: "cons-mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @incident = Incident.create!(property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response", damage_type: "flood", description: "Consumables")
    @hepa = ConsumableType.create!(organization: @genixo, name: "HEPA Filter Air Scrubber Small", position: 0)
    @disposal = ConsumableType.create!(organization: @genixo, name: "Disposal", position: 1)
    @date = Date.current
  end

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end

  # as: :json matches production: Inertia's router posts JSON bodies, which is
  # also what keeps an array of row objects intact (form encoding would merge
  # rows with disjoint keys).
  def save_day(entries, log_date: @date, incident: @incident)
    post incident_consumable_entries_path(incident),
      params: { log_date: log_date.iso8601, entries: entries }, as: :json
  end

  test "saves the day's sheet: typed rows, write-ins, and drops blank/zero rows" do
    login_as @manager

    save_day([
      { consumable_type_id: @hepa.id, quantity: "3" },
      { consumable_type_id: @disposal.id, quantity: "0" },
      { custom_name: "Ozone generator pads", quantity: "2" },
      { custom_name: "", quantity: "5" },
      { custom_name: "No quantity item", quantity: "" }
    ])

    assert_redirected_to incident_path(@incident)
    entries = @incident.consumable_entries.for_date(@date)
    assert_equal 2, entries.count
    assert_equal 3, entries.find_by(consumable_type: @hepa).quantity
    assert_equal 2, entries.find_by(custom_name: "Ozone generator pads").quantity
    assert_equal @manager, entries.first.logged_by_user
  end

  test "resaving a day replaces its entries instead of stacking duplicates" do
    login_as @manager
    save_day([ { consumable_type_id: @hepa.id, quantity: "3" } ])
    save_day([ { consumable_type_id: @hepa.id, quantity: "5" } ])

    entries = @incident.consumable_entries.for_date(@date)
    assert_equal 1, entries.count
    assert_equal 5, entries.first.quantity
  end

  test "saving a different day leaves other days untouched" do
    login_as @manager
    save_day([ { consumable_type_id: @hepa.id, quantity: "3" } ], log_date: @date - 1.day)
    save_day([ { consumable_type_id: @disposal.id, quantity: "1" } ])

    assert_equal 1, @incident.consumable_entries.for_date(@date - 1.day).count
    assert_equal 1, @incident.consumable_entries.for_date(@date).count
  end

  test "logs a consumables_logged activity event with date and count" do
    login_as @manager

    assert_difference -> { @incident.activity_events.where(event_type: "consumables_logged").count }, 1 do
      save_day([ { consumable_type_id: @hepa.id, quantity: "3" } ])
    end
    event = @incident.activity_events.where(event_type: "consumables_logged").last
    assert_equal @date.iso8601, event.metadata["log_date"]
    assert_equal 1, event.metadata["count"]
  end

  test "a consumable type from another org 404s and stores nothing" do
    other_org = Organization.create!(name: "Other Mitigation", organization_type: "mitigation")
    foreign_type = ConsumableType.create!(organization: other_org, name: "Foreign Item")
    login_as @manager

    # Plain form post: the single row survives form encoding, and the 404
    # renders through the HTML/Inertia path like a real browser request.
    post incident_consumable_entries_path(@incident),
      params: { log_date: @date.iso8601, entries: [ { consumable_type_id: foreign_type.id, quantity: "3" } ] }
    assert_response :not_found
    assert_equal 0, @incident.consumable_entries.count
  end

  test "rejects an invalid date" do
    login_as @manager
    post incident_consumable_entries_path(@incident),
      params: { log_date: "not-a-date", entries: [ { consumable_type_id: @hepa.id, quantity: "3" } ] }

    assert_redirected_to incident_path(@incident)
    assert_match(/invalid date/, flash[:alert])
    assert_equal 0, @incident.consumable_entries.count
  end

  test "requires manage_daily_logs" do
    @manager.update!(permissions: @manager.permissions - [ Permissions::MANAGE_DAILY_LOGS.to_s ])
    login_as @manager

    save_day([ { consumable_type_id: @hepa.id, quantity: "3" } ])
    assert_response :not_found
  end

  test "is scoped through visible_incidents" do
    other_pm_org = Organization.create!(name: "Unrelated PM Co", organization_type: "property_management")
    other_pm = User.create!(organization: other_pm_org, user_type: "property_manager",
      email_address: "other-pm-cons@other.com", first_name: "Other", last_name: "PM", password: "password123")
    login_as other_pm

    save_day([ { consumable_type_id: @hepa.id, quantity: "3" } ])
    assert_response :not_found
  end
end
