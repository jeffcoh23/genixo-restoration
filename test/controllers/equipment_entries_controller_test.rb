require "test_helper"

class EquipmentEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @sandalwood = Organization.create!(name: "Sandalwood", organization_type: "property_management")

    @property = Property.create!(
      name: "Sunset Apartments", property_management_org: @greystar,
      mitigation_org: @genixo
    )

    @manager = User.create!(organization: @genixo, user_type: User::MANAGER,
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: User::TECHNICIAN,
      email_address: "tech@genixo.com", first_name: "Test", last_name: "Tech", password: "password123")
    @other_tech = User.create!(organization: @genixo, user_type: User::TECHNICIAN,
      email_address: "tech2@genixo.com", first_name: "Other", last_name: "Tech", password: "password123")
    @office_sales = User.create!(organization: @genixo, user_type: User::OFFICE_SALES,
      email_address: "sales@genixo.com", first_name: "Test", last_name: "Sales", password: "password123")
    @pm_user = User.create!(organization: @greystar, user_type: User::PROPERTY_MANAGER,
      email_address: "pm@greystar.com", first_name: "Test", last_name: "PM", password: "password123")
    @cross_org_pm = User.create!(organization: @sandalwood, user_type: User::PROPERTY_MANAGER,
      email_address: "pm@sandalwood.com", first_name: "Cross", last_name: "PM", password: "password123")

    PropertyAssignment.create!(user: @pm_user, property: @property)

    @incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "flood", description: "Test incident", emergency: true
    )
    IncidentAssignment.create!(incident: @incident, user: @tech, assigned_by_user: @manager)
    IncidentAssignment.create!(incident: @incident, user: @other_tech, assigned_by_user: @manager)

    @dehumidifier = EquipmentType.create!(organization: @genixo, name: "Dehumidifier")
  end

  # --- Create tests ---

  test "manager can place equipment with equipment_type_id" do
    login_as @manager
    assert_difference "EquipmentEntry.count", 1 do
      post incident_equipment_entries_path(@incident), params: {
        equipment_entry: {
          equipment_type_id: @dehumidifier.id,
          equipment_identifier: "DH-001",
          placed_at: Time.current.iso8601,
          location_notes: "Unit 238, bedroom"
        }
      }
    end
    assert_redirected_to incident_path(@incident)
    entry = EquipmentEntry.last
    assert_equal @dehumidifier.id, entry.equipment_type_id
    assert_equal "DH-001", entry.equipment_identifier
    assert_equal @manager.id, entry.logged_by_user_id
    assert_nil entry.removed_at
  end

  test "manager can place equipment with freeform type" do
    login_as @manager
    assert_difference "EquipmentEntry.count", 1 do
      post incident_equipment_entries_path(@incident), params: {
        equipment_entry: {
          equipment_type_other: "Custom Blower",
          placed_at: Time.current.iso8601,
          location_notes: "Hallway"
        }
      }
    end
    assert_redirected_to incident_path(@incident)
    entry = EquipmentEntry.last
    assert_nil entry.equipment_type_id
    assert_equal "Custom Blower", entry.equipment_type_other
  end

  test "tech can place equipment" do
    login_as @tech
    assert_difference "EquipmentEntry.count", 1 do
      post incident_equipment_entries_path(@incident), params: {
        equipment_entry: {
          equipment_type_id: @dehumidifier.id,
          placed_at: Time.current.iso8601,
          location_notes: "Kitchen"
        }
      }
    end
    assert_redirected_to incident_path(@incident)
    assert_equal @tech.id, EquipmentEntry.last.logged_by_user_id
  end

  test "office_sales cannot place equipment" do
    login_as @office_sales
    assert_no_difference "EquipmentEntry.count" do
      post incident_equipment_entries_path(@incident), params: {
        equipment_entry: {
          equipment_type_id: @dehumidifier.id,
          placed_at: Time.current.iso8601
        }
      }
    end
    assert_response :not_found
  end

  test "PM user cannot place equipment" do
    login_as @pm_user
    assert_no_difference "EquipmentEntry.count" do
      post incident_equipment_entries_path(@incident), params: {
        equipment_entry: {
          equipment_type_id: @dehumidifier.id,
          placed_at: Time.current.iso8601
        }
      }
    end
    assert_response :not_found
  end

  test "cross-org PM user cannot place equipment" do
    login_as @cross_org_pm
    assert_no_difference "EquipmentEntry.count" do
      post incident_equipment_entries_path(@incident), params: {
        equipment_entry: {
          equipment_type_id: @dehumidifier.id,
          placed_at: Time.current.iso8601
        }
      }
    end
    assert_response :not_found
  end

  # --- Update tests ---

  test "manager can update any entry on visible incident" do
    login_as @manager
    entry = create_entry(logged_by: @tech)
    patch incident_equipment_entry_path(@incident, entry), params: {
      equipment_entry: { location_notes: "Updated location" }
    }
    assert_redirected_to incident_path(@incident)
    assert_equal "Updated location", entry.reload.location_notes
  end

  test "tech can update own entry" do
    login_as @tech
    entry = create_entry(logged_by: @tech)
    patch incident_equipment_entry_path(@incident, entry), params: {
      equipment_entry: { location_notes: "Tech updated" }
    }
    assert_redirected_to incident_path(@incident)
    assert_equal "Tech updated", entry.reload.location_notes
  end

  test "tech cannot update another users entry" do
    login_as @tech
    entry = create_entry(logged_by: @other_tech)
    patch incident_equipment_entry_path(@incident, entry), params: {
      equipment_entry: { location_notes: "Should not work" }
    }
    assert_response :not_found
    assert_not_equal "Should not work", entry.reload.location_notes
  end

  # --- Remove tests ---

  test "manager can remove equipment" do
    login_as @manager
    entry = create_entry(logged_by: @tech)
    assert_nil entry.removed_at
    patch remove_incident_equipment_entry_path(@incident, entry)
    assert_redirected_to incident_path(@incident)
    assert_not_nil entry.reload.removed_at
  end

  test "tech can remove own equipment" do
    login_as @tech
    entry = create_entry(logged_by: @tech)
    patch remove_incident_equipment_entry_path(@incident, entry)
    assert_redirected_to incident_path(@incident)
    assert_not_nil entry.reload.removed_at
  end

  test "tech cannot remove another users equipment" do
    login_as @tech
    entry = create_entry(logged_by: @other_tech)
    patch remove_incident_equipment_entry_path(@incident, entry)
    assert_response :not_found
    assert_nil entry.reload.removed_at
  end

  # --- Activity event tests ---

  test "creates activity event on place" do
    login_as @manager
    assert_difference "ActivityEvent.count", 1 do
      post incident_equipment_entries_path(@incident), params: {
        equipment_entry: {
          equipment_type_id: @dehumidifier.id,
          equipment_identifier: "DH-100",
          placed_at: Time.current.iso8601,
          location_notes: "Bedroom"
        }
      }
    end
    event = ActivityEvent.last
    assert_equal "equipment_placed", event.event_type
    assert_equal @manager.id, event.performed_by_user_id
    assert_equal "Dehumidifier", event.metadata["type_name"]
    assert_equal "DH-100", event.metadata["equipment_identifier"]
    assert_not_nil @incident.reload.last_activity_at
  end

  test "creates activity event on remove" do
    login_as @manager
    entry = create_entry(logged_by: @tech)
    assert_difference "ActivityEvent.count", 1 do
      patch remove_incident_equipment_entry_path(@incident, entry)
    end
    event = ActivityEvent.last
    assert_equal "equipment_removed", event.event_type
  end

  private

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end

  def create_entry(logged_by:)
    @incident.equipment_entries.create!(
      equipment_type: @dehumidifier,
      equipment_identifier: "DH-TEST",
      placed_at: Time.current,
      location_notes: "Test location",
      logged_by_user: logged_by
    )
  end
end
