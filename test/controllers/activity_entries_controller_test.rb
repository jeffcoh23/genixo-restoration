require "test_helper"

class ActivityEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")

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

    PropertyAssignment.create!(user: @pm_user, property: @property)

    @incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "flood", description: "Test incident", emergency: true
    )
    IncidentAssignment.create!(incident: @incident, user: @tech, assigned_by_user: @manager)

    @dehumidifier = EquipmentType.create!(organization: @genixo, name: "Dehumidifier")
  end

  # --- Create tests ---

  test "manager can create activity entry" do
    login_as @manager
    assert_difference "ActivityEntry.count", 1 do
      post incident_activity_entries_path(@incident), params: {
        activity_entry: {
          title: "Initial moisture readings",
          details: "Readings taken in all affected units",
          status: "active",
          occurred_at: Time.current.iso8601,
          units_affected: 3,
          units_affected_description: "Units 101, 102, 103"
        }
      }
    end
    assert_redirected_to incident_path(@incident)
    entry = ActivityEntry.last
    assert_equal "Initial moisture readings", entry.title
    assert_equal "active", entry.status
    assert_equal @manager.id, entry.performed_by_user_id
    assert_equal 3, entry.units_affected
  end

  test "tech can create activity entry" do
    login_as @tech
    assert_difference "ActivityEntry.count", 1 do
      post incident_activity_entries_path(@incident), params: {
        activity_entry: {
          title: "Set up drying equipment",
          status: "active",
          occurred_at: Time.current.iso8601
        }
      }
    end
    assert_redirected_to incident_path(@incident)
    assert_equal @tech.id, ActivityEntry.last.performed_by_user_id
  end

  test "create with equipment actions" do
    login_as @manager
    assert_difference [ "ActivityEntry.count", "ActivityEquipmentAction.count" ], 1 do
      post incident_activity_entries_path(@incident), params: {
        activity_entry: {
          title: "Placed dehumidifier in unit 101",
          status: "active",
          occurred_at: Time.current.iso8601,
          equipment_actions: [
            {
              action_type: "add",
              quantity: 2,
              equipment_type_id: @dehumidifier.id,
              note: "Bedroom and living room"
            }
          ]
        }
      }
    end
    assert_redirected_to incident_path(@incident)
    entry = ActivityEntry.last
    assert_equal 1, entry.equipment_actions.count
    action = entry.equipment_actions.first
    assert_equal "add", action.action_type
    assert_equal 2, action.quantity
    assert_equal @dehumidifier.id, action.equipment_type_id
    assert_equal "Bedroom and living room", action.note
  end

  test "create with multiple equipment actions" do
    login_as @tech
    post incident_activity_entries_path(@incident), params: {
      activity_entry: {
        title: "Equipment rotation",
        status: "active",
        occurred_at: Time.current.iso8601,
        equipment_actions: [
          { action_type: "add", quantity: 3, equipment_type_id: @dehumidifier.id, position: 0 },
          { action_type: "remove", quantity: 1, equipment_type_other: "Fan", position: 1 }
        ]
      }
    }
    assert_redirected_to incident_path(@incident)
    entry = ActivityEntry.last
    assert_equal 2, entry.equipment_actions.count
    assert_equal %w[add remove], entry.equipment_actions.order(:position).map(&:action_type)
  end

  test "create accepts indexed equipment_actions hash from Inertia-style payload" do
    login_as @manager

    assert_difference [ "ActivityEntry.count", "ActivityEquipmentAction.count" ], 1 do
      post incident_activity_entries_path(@incident), params: {
        activity_entry: {
          title: "Indexed equipment actions payload",
          status: "active",
          occurred_at: Time.current.iso8601,
          equipment_actions: {
            "0" => {
              action_type: "add",
              quantity: 2,
              equipment_type_id: @dehumidifier.id,
              note: "Placed in unit 101",
              position: 0
            }
          }
        }
      }
    end

    entry = ActivityEntry.last
    assert_equal 1, entry.equipment_actions.count
    action = entry.equipment_actions.first
    assert_equal "add", action.action_type
    assert_equal 2, action.quantity
    assert_equal @dehumidifier.id, action.equipment_type_id
  end

  test "create persists daily log fields from UI payload" do
    login_as @manager

    post incident_activity_entries_path(@incident), params: {
      activity_entry: {
        title: "Daily log update",
        status: "Complete",
        occurred_at: Date.current.iso8601,
        units_affected: "2",
        units_affected_description: "Units 101 and 102",
        details: "Removed baseboards and set containment",
        visitors: "Resident in unit 101",
        usable_rooms_returned: "Unit 100 kitchen",
        estimated_date_of_return: (Date.current + 2.days).iso8601
      }
    }

    assert_redirected_to incident_path(@incident)
    entry = ActivityEntry.last
    assert_equal "Daily log update", entry.title
    assert_equal "Complete", entry.status
    assert_equal 2, entry.units_affected
    assert_equal "Units 101 and 102", entry.units_affected_description
    assert_equal "Removed baseboards and set containment", entry.details
    assert_equal "Resident in unit 101", entry.visitors
    assert_equal "Unit 100 kitchen", entry.usable_rooms_returned
    assert_equal Date.current + 2.days, entry.estimated_date_of_return
  end

  test "create with freeform equipment type" do
    login_as @tech
    post incident_activity_entries_path(@incident), params: {
      activity_entry: {
        title: "Custom equipment placed",
        status: "active",
        occurred_at: Time.current.iso8601,
        equipment_actions: [
          { action_type: "add", quantity: 1, equipment_type_other: "Industrial Blower" }
        ]
      }
    }
    assert_redirected_to incident_path(@incident)
    action = ActivityEntry.last.equipment_actions.first
    assert_nil action.equipment_type_id
    assert_equal "Industrial Blower", action.equipment_type_other
  end

  test "create logs activity event" do
    login_as @manager
    assert_difference "ActivityEvent.count", 1 do
      post incident_activity_entries_path(@incident), params: {
        activity_entry: {
          title: "Moisture readings",
          status: "active",
          occurred_at: Time.current.iso8601
        }
      }
    end
    event = ActivityEvent.last
    assert_equal "activity_logged", event.event_type
    assert_equal @manager.id, event.performed_by_user_id
    assert_equal "Moisture readings", event.metadata["title"]
  end

  test "create with missing title returns error" do
    login_as @manager
    assert_no_difference "ActivityEntry.count" do
      post incident_activity_entries_path(@incident), params: {
        activity_entry: {
          title: "",
          status: "active",
          occurred_at: Time.current.iso8601
        }
      }
    end
    assert_redirected_to incident_path(@incident)
  end

  # --- Authorization tests ---

  test "office_sales cannot create activity entry" do
    login_as @office_sales
    assert_no_difference "ActivityEntry.count" do
      post incident_activity_entries_path(@incident), params: {
        activity_entry: {
          title: "Should not work",
          status: "active",
          occurred_at: Time.current.iso8601
        }
      }
    end
    assert_response :not_found
  end

  test "PM user cannot create activity entry" do
    login_as @pm_user
    assert_no_difference "ActivityEntry.count" do
      post incident_activity_entries_path(@incident), params: {
        activity_entry: {
          title: "Should not work",
          status: "active",
          occurred_at: Time.current.iso8601
        }
      }
    end
    assert_response :not_found
  end

  # --- Update tests ---

  test "manager can update any activity entry" do
    login_as @manager
    entry = create_entry(performed_by: @tech)
    patch incident_activity_entry_path(@incident, entry), params: {
      activity_entry: {
        title: "Updated by manager",
        status: "completed",
        occurred_at: entry.occurred_at.iso8601
      }
    }
    assert_redirected_to incident_path(@incident)
    entry.reload
    assert_equal "Updated by manager", entry.title
    assert_equal "completed", entry.status
  end

  test "tech can update own activity entry" do
    login_as @tech
    entry = create_entry(performed_by: @tech)
    patch incident_activity_entry_path(@incident, entry), params: {
      activity_entry: {
        title: "Updated by tech",
        status: "active",
        occurred_at: entry.occurred_at.iso8601
      }
    }
    assert_redirected_to incident_path(@incident)
    assert_equal "Updated by tech", entry.reload.title
  end

  test "tech cannot update another users activity entry" do
    login_as @tech
    entry = create_entry(performed_by: @other_tech)
    patch incident_activity_entry_path(@incident, entry), params: {
      activity_entry: {
        title: "Should not work",
        status: "active",
        occurred_at: entry.occurred_at.iso8601
      }
    }
    assert_response :not_found
    assert_not_equal "Should not work", entry.reload.title
  end

  test "update replaces equipment actions" do
    login_as @manager
    entry = create_entry(performed_by: @manager)
    entry.equipment_actions.create!(
      action_type: "add", quantity: 1,
      equipment_type: @dehumidifier, position: 0
    )
    assert_equal 1, entry.equipment_actions.count

    patch incident_activity_entry_path(@incident, entry), params: {
      activity_entry: {
        title: entry.title,
        status: entry.status,
        occurred_at: entry.occurred_at.iso8601,
        equipment_actions: [
          { action_type: "add", quantity: 3, equipment_type_id: @dehumidifier.id, position: 0 },
          { action_type: "remove", quantity: 1, equipment_type_other: "Fan", position: 1 }
        ]
      }
    }
    assert_redirected_to incident_path(@incident)
    assert_equal 2, entry.reload.equipment_actions.count
  end

  test "update logs activity event" do
    login_as @manager
    entry = create_entry(performed_by: @manager)
    assert_difference "ActivityEvent.count", 1 do
      patch incident_activity_entry_path(@incident, entry), params: {
        activity_entry: {
          title: "Updated title",
          status: "completed",
          occurred_at: entry.occurred_at.iso8601
        }
      }
    end
    event = ActivityEvent.last
    assert_equal "activity_updated", event.event_type
    assert_equal "Updated title", event.metadata["title"]
    assert_equal "completed", event.metadata["status"]
  end

  test "update with invalid data returns error" do
    login_as @manager
    entry = create_entry(performed_by: @manager)
    patch incident_activity_entry_path(@incident, entry), params: {
      activity_entry: {
        title: "",
        status: "active",
        occurred_at: entry.occurred_at.iso8601
      }
    }
    assert_redirected_to incident_path(@incident)
    assert_not_equal "", entry.reload.title
  end

  private

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end

  def create_entry(performed_by:)
    @incident.activity_entries.create!(
      title: "Test activity",
      details: "Test details",
      status: "active",
      occurred_at: Time.current,
      performed_by_user: performed_by
    )
  end
end
