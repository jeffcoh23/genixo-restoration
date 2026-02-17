require "test_helper"

class LaborEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @sandalwood = Organization.create!(name: "Sandalwood", organization_type: "property_management")

    @property = Property.create!(
      name: "Sunset Apartments", property_management_org: @greystar,
      mitigation_org: @genixo
    )

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "Test", last_name: "Tech", password: "password123")
    @other_tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech2@genixo.com", first_name: "Other", last_name: "Tech", password: "password123")
    @office_sales = User.create!(organization: @genixo, user_type: "office_sales",
      email_address: "sales@genixo.com", first_name: "Test", last_name: "Sales", password: "password123")
    @pm_user = User.create!(organization: @greystar, user_type: "property_manager",
      email_address: "pm@greystar.com", first_name: "Test", last_name: "PM", password: "password123")
    @cross_org_pm = User.create!(organization: @sandalwood, user_type: "property_manager",
      email_address: "pm@sandalwood.com", first_name: "Cross", last_name: "PM", password: "password123")

    PropertyAssignment.create!(user: @pm_user, property: @property)

    @incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "flood", description: "Test incident", emergency: true
    )
    IncidentAssignment.create!(incident: @incident, user: @tech, assigned_by_user: @manager)
    IncidentAssignment.create!(incident: @incident, user: @other_tech, assigned_by_user: @manager)

    @started = Time.zone.parse("2026-02-15 08:00:00")
    @ended = Time.zone.parse("2026-02-15 12:30:00")
  end

  # --- Create tests ---

  test "manager can create labor entry with user_id" do
    login_as @manager
    assert_difference "LaborEntry.count", 1 do
      post incident_labor_entries_path(@incident), params: {
        labor_entry: {
          role_label: "Technician", log_date: Date.current,
          started_at: @started.iso8601, ended_at: @ended.iso8601,
          user_id: @tech.id
        }
      }
    end
    assert_redirected_to incident_path(@incident)
    entry = LaborEntry.last
    assert_equal @tech.id, entry.user_id
    assert_equal @manager.id, entry.created_by_user_id
    assert_equal 4.5, entry.hours.to_f
  end

  test "manager can create generic labor entry without user_id" do
    login_as @manager
    assert_difference "LaborEntry.count", 1 do
      post incident_labor_entries_path(@incident), params: {
        labor_entry: {
          role_label: "Helper", log_date: Date.current,
          started_at: @started.iso8601, ended_at: @ended.iso8601
        }
      }
    end
    assert_redirected_to incident_path(@incident)
    assert_nil LaborEntry.last.user_id
  end

  test "tech can create labor entry forced to self" do
    login_as @tech
    assert_difference "LaborEntry.count", 1 do
      post incident_labor_entries_path(@incident), params: {
        labor_entry: {
          role_label: "Technician", log_date: Date.current,
          started_at: @started.iso8601, ended_at: @ended.iso8601
        }
      }
    end
    assert_redirected_to incident_path(@incident)
    assert_equal @tech.id, LaborEntry.last.user_id
    assert_equal @tech.id, LaborEntry.last.created_by_user_id
  end

  test "tech cannot set user_id to another user" do
    login_as @tech
    post incident_labor_entries_path(@incident), params: {
      labor_entry: {
        role_label: "Technician", log_date: Date.current,
        started_at: @started.iso8601, ended_at: @ended.iso8601,
        user_id: @other_tech.id
      }
    }
    assert_redirected_to incident_path(@incident)
    assert_equal @tech.id, LaborEntry.last.user_id
  end

  test "office_sales cannot create labor entry" do
    login_as @office_sales
    assert_no_difference "LaborEntry.count" do
      post incident_labor_entries_path(@incident), params: {
        labor_entry: {
          role_label: "Technician", log_date: Date.current,
          started_at: @started.iso8601, ended_at: @ended.iso8601
        }
      }
    end
    assert_response :not_found
  end

  test "PM user cannot create labor entry" do
    login_as @pm_user
    assert_no_difference "LaborEntry.count" do
      post incident_labor_entries_path(@incident), params: {
        labor_entry: {
          role_label: "Technician", log_date: Date.current,
          started_at: @started.iso8601, ended_at: @ended.iso8601
        }
      }
    end
    assert_response :not_found
  end

  test "cross-org PM user cannot create labor entry" do
    login_as @cross_org_pm
    assert_no_difference "LaborEntry.count" do
      post incident_labor_entries_path(@incident), params: {
        labor_entry: {
          role_label: "Technician", log_date: Date.current,
          started_at: @started.iso8601, ended_at: @ended.iso8601
        }
      }
    end
    assert_response :not_found
  end

  # --- Update tests ---

  test "manager can update any entry on visible incident" do
    login_as @manager
    entry = create_labor_entry(user: @tech, created_by_user: @tech, hours: 2.0)
    new_ended = Time.zone.parse("2026-02-15 13:00:00")
    patch incident_labor_entry_path(@incident, entry), params: {
      labor_entry: { ended_at: new_ended.iso8601 }
    }
    assert_redirected_to incident_path(@incident)
    assert_equal 5.0, entry.reload.hours.to_f
  end

  test "tech can update own entry" do
    login_as @tech
    entry = create_labor_entry(user: @tech, created_by_user: @tech, hours: 2.0)
    new_ended = Time.zone.parse("2026-02-15 11:00:00")
    patch incident_labor_entry_path(@incident, entry), params: {
      labor_entry: { ended_at: new_ended.iso8601 }
    }
    assert_redirected_to incident_path(@incident)
    assert_equal 3.0, entry.reload.hours.to_f
  end

  test "tech cannot update another users entry" do
    login_as @tech
    entry = create_labor_entry(user: @other_tech, created_by_user: @other_tech, hours: 2.0)
    new_ended = Time.zone.parse("2026-02-15 17:00:00")
    patch incident_labor_entry_path(@incident, entry), params: {
      labor_entry: { ended_at: new_ended.iso8601 }
    }
    assert_response :not_found
    assert_equal 2.0, entry.reload.hours.to_f
  end

  # --- Activity + calculation tests ---

  test "creates activity event and touches last_activity_at" do
    login_as @manager
    assert_difference "ActivityEvent.count", 1 do
      post incident_labor_entries_path(@incident), params: {
        labor_entry: {
          role_label: "Technician", log_date: Date.current,
          started_at: @started.iso8601, ended_at: @ended.iso8601,
          user_id: @tech.id
        }
      }
    end
    event = ActivityEvent.last
    assert_equal "labor_created", event.event_type
    assert_equal @manager.id, event.performed_by_user_id
    assert_equal "Technician", event.metadata["role_label"]
    assert_equal 4.5, event.metadata["hours"]
    assert_not_nil @incident.reload.last_activity_at
  end

  test "hours always calculated from started_at and ended_at" do
    login_as @manager
    started = Time.zone.parse("2026-02-15 08:00:00")
    ended = Time.zone.parse("2026-02-15 11:30:00")
    post incident_labor_entries_path(@incident), params: {
      labor_entry: {
        role_label: "Technician", log_date: Date.current,
        started_at: started.iso8601, ended_at: ended.iso8601,
        user_id: @tech.id
      }
    }
    assert_redirected_to incident_path(@incident)
    assert_equal 3.5, LaborEntry.last.hours.to_f
  end

  private

  def create_labor_entry(user:, created_by_user:, hours:)
    @incident.labor_entries.create!(
      role_label: "Technician", log_date: Date.current,
      started_at: @started, ended_at: @started + hours.hours,
      hours: hours,
      user: user, created_by_user: created_by_user
    )
  end

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end
end
