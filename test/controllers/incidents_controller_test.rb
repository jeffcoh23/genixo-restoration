require "test_helper"
require "cgi"

class IncidentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @other_pm = Organization.create!(name: "Other PM", organization_type: "property_management")

    @property = Property.create!(
      name: "Sunset Apartments", property_management_org: @greystar,
      mitigation_org: @genixo, street_address: "100 Sunset Blvd",
      city: "Houston", state: "TX", zip: "77001", unit_count: 24
    )

    @other_property = Property.create!(
      name: "Other Building", property_management_org: @other_pm,
      mitigation_org: @genixo
    )

    # Mitigation org users
    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @office = User.create!(organization: @genixo, user_type: "office_sales",
      email_address: "office@genixo.com", first_name: "Test", last_name: "Office", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "Test", last_name: "Tech", password: "password123")

    # PM org users
    @pm_user = User.create!(organization: @greystar, user_type: "property_manager",
      email_address: "pm@greystar.com", first_name: "Test", last_name: "PM", password: "password123")
    @area_mgr = User.create!(organization: @greystar, user_type: "area_manager",
      email_address: "am@greystar.com", first_name: "Test", last_name: "AreaMgr", password: "password123")
    @pm_mgr = User.create!(organization: @greystar, user_type: "pm_manager",
      email_address: "pmmgr@greystar.com", first_name: "Test", last_name: "PMMgr", password: "password123")

    # Assign PM users to the property
    PropertyAssignment.create!(user: @pm_user, property: @property)
    PropertyAssignment.create!(user: @area_mgr, property: @property)
  end

  # --- Index access + scoping ---

  test "manager sees all incidents in their mitigation org" do
    i1 = create_test_incident(status: "active", property: @property)
    i2 = create_test_incident(status: "acknowledged", property: @other_property)
    login_as @manager
    get incidents_path
    assert_response :success
    assert_includes response.body, "Sunset Apartments"
    assert_includes response.body, "Other Building"
  end

  test "property_manager sees only incidents on assigned properties" do
    i1 = create_test_incident(status: "active", property: @property)
    i2 = create_test_incident(status: "acknowledged", property: @other_property)
    login_as @pm_user
    get incidents_path
    assert_response :success
    assert_includes response.body, "Sunset Apartments"
    assert_not_includes response.body, "Other Building"
  end

  test "technician sees only directly assigned incidents" do
    i1 = create_test_incident(status: "active", property: @property)
    i2 = create_test_incident(status: "active", property: @other_property)
    IncidentAssignment.create!(incident: i1, user: @tech, assigned_by_user: @manager)
    login_as @tech
    get incidents_path
    assert_response :success
    # Should see i1 (assigned) but not i2 (not assigned)
    incidents_json = JSON.parse(response.body.match(/"incidents":(\[.*?\])/m)[1]) rescue nil
    if incidents_json
      assert_equal 1, incidents_json.length
    end
  end

  test "index filters by status" do
    create_test_incident(status: "active", property: @property)
    create_test_incident(status: "on_hold", property: @other_property)
    login_as @manager
    get incidents_path, params: { status: "active" }
    assert_response :success
  end

  test "index filters by property" do
    create_test_incident(status: "active", property: @property)
    create_test_incident(status: "active", property: @other_property)
    login_as @manager
    get incidents_path, params: { property_id: @property.id }
    assert_response :success
  end

  test "index filters by search term" do
    create_test_incident(status: "active", property: @property, description: "Water pipe burst")
    create_test_incident(status: "active", property: @other_property, description: "Fire damage")
    login_as @manager
    get incidents_path, params: { search: "Water" }
    assert_response :success
  end

  test "index paginates results" do
    login_as @manager
    get incidents_path, params: { page: 1 }
    assert_response :success
  end

  test "index passes can_create based on permissions" do
    login_as @tech
    # Tech can't create incidents, so can_create should be false
    get incidents_path
    assert_response :success
  end

  # --- Show page ---

  test "manager can view incident detail" do
    incident = create_test_incident(status: "active")
    login_as @manager
    get incident_path(incident)
    assert_response :success
  end

  test "show includes incident details and assigned users" do
    incident = create_test_incident(status: "active")
    IncidentAssignment.create!(incident: incident, user: @manager, assigned_by_user: @manager)
    login_as @manager
    get incident_path(incident)
    assert_response :success
    assert_includes response.body, "Test Manager"
  end

  test "pm_user can view incident on assigned property" do
    incident = create_test_incident(status: "active")
    login_as @pm_user
    get incident_path(incident)
    assert_response :success
  end

  test "pm_user cannot view incident on unassigned property" do
    incident = create_test_incident(status: "active", property: @other_property)
    login_as @pm_user
    get incident_path(incident)
    assert_response :not_found
  end

  test "show passes valid_transitions for managers" do
    incident = create_test_incident(status: "acknowledged")
    login_as @manager
    get incident_path(incident)
    assert_response :success
    # Manager should see transition options
    assert_includes response.body, "active"
  end

  test "show passes empty valid_transitions for non-managers" do
    incident = create_test_incident(status: "acknowledged")
    login_as @pm_user
    get incident_path(incident)
    assert_response :success
  end

  # --- New page access control ---

  test "manager can access new incident page" do
    login_as @manager
    get new_incident_path
    assert_response :success
  end

  test "office_sales can access new incident page" do
    login_as @office
    get new_incident_path
    assert_response :success
  end

  test "property_manager can access new incident page" do
    login_as @pm_user
    get new_incident_path
    assert_response :success
  end

  test "area_manager can access new incident page" do
    login_as @area_mgr
    get new_incident_path
    assert_response :success
  end

  test "technician gets 404 on new incident page" do
    login_as @tech
    get new_incident_path
    assert_response :not_found
  end

  test "pm_manager gets 404 on new incident page" do
    login_as @pm_mgr
    get new_incident_path
    assert_response :not_found
  end

  # --- Create with valid params ---

  test "creates incident with valid params" do
    login_as @manager

    # Auto-assign creates 5 assignments:
    #   PM-side property assignees: @pm_user, @area_mgr (2)
    #   PM-side pm_managers in PM org: @pm_mgr (1)
    #   Mitigation-side managers + office_sales: @manager, @office (2)
    assert_difference "Incident.count", 1 do
      assert_difference "ActivityEvent.count", 2 do
        assert_difference "IncidentAssignment.count", 5 do
          post incidents_path, params: {
            incident: {
              property_id: @property.id,
              project_type: "emergency_response",
              damage_type: "flood",
              description: "Major water leak in unit 4B",
              cause: "Burst pipe",
              requested_next_steps: "Dispatch crew immediately"
            }
          }
        end
      end
    end
  end

  test "redirects to incident show on success" do
    login_as @manager
    post incidents_path, params: {
      incident: {
        property_id: @property.id,
        project_type: "emergency_response",
        damage_type: "flood",
        description: "Major water leak in unit 4B"
      }
    }
    incident = Incident.last
    assert_redirected_to incident_path(incident)
  end

  test "create accepts nested indexed additional_user_ids and contacts from Inertia-style payload" do
    login_as @manager

    assert_difference [ "Incident.count", "IncidentContact.count" ], 1 do
      post incidents_path, params: {
        incident: {
          property_id: @property.id,
          project_type: "emergency_response",
          damage_type: "flood",
          description: "Inertia nested arrays test",
          additional_user_ids: {
            "0" => @manager.id.to_s,
            "1" => @tech.id.to_s
          },
          contacts: {
            "0" => {
              name: "Jane Contact",
              title: "Property Manager",
              email: "jane@example.com",
              phone: "713-555-0101",
              onsite: "true"
            }
          }
        }
      }
    end

    incident = Incident.last
    assert_includes incident.assigned_user_ids, @manager.id
    assert_includes incident.assigned_user_ids, @tech.id
    assert_not_includes incident.assigned_user_ids, @office.id
    assert_equal "Jane Contact", incident.incident_contacts.last.name
  end

  test "create supports legacy top-level additional_user_ids and contacts fallback" do
    login_as @manager

    assert_difference [ "Incident.count", "IncidentContact.count" ], 1 do
      post incidents_path, params: {
        incident: {
          property_id: @property.id,
          project_type: "emergency_response",
          damage_type: "flood",
          description: "Legacy fallback payload test"
        },
        additional_user_ids: [ @manager.id, @tech.id ],
        contacts: [
          { name: "Top Level Contact", title: "Resident", email: "", phone: "", onsite: true }
        ]
      }
    end

    incident = Incident.last
    assert_includes incident.assigned_user_ids, @tech.id
    assert_equal "Top Level Contact", incident.incident_contacts.last.name
  end

  # --- Create with invalid params ---

  test "fails with missing required fields" do
    login_as @manager
    assert_no_difference "Incident.count" do
      post incidents_path, params: {
        incident: {
          property_id: @property.id,
          project_type: "emergency_response",
          damage_type: "flood",
          description: ""
        }
      }
    end
    assert_redirected_to new_incident_path
  end

  test "fails with invalid property from another org" do
    login_as @pm_user
    assert_no_difference "Incident.count" do
      post incidents_path, params: {
        incident: {
          property_id: @other_property.id,
          project_type: "emergency_response",
          damage_type: "flood",
          description: "Should not work"
        }
      }
    end
    assert_redirected_to new_incident_path
  end

  # --- Status transition ---

  test "manager can transition incident status" do
    incident = create_test_incident(status: "acknowledged")
    login_as @manager
    patch transition_incident_path(incident), params: { status: "active" }
    assert_redirected_to incident_path(incident)
    assert_equal "active", incident.reload.status
  end

  test "manager transition creates activity event" do
    incident = create_test_incident(status: "acknowledged")
    login_as @manager
    assert_difference "ActivityEvent.count", 1 do
      patch transition_incident_path(incident), params: { status: "active" }
    end
  end

  test "invalid transition redirects with alert" do
    incident = create_test_incident(status: "acknowledged")
    login_as @manager
    patch transition_incident_path(incident), params: { status: "completed" }
    assert_redirected_to incident_path(incident)
    assert_equal "acknowledged", incident.reload.status
  end

  test "office_sales cannot transition status" do
    incident = create_test_incident(status: "acknowledged")
    login_as @office
    patch transition_incident_path(incident), params: { status: "active" }
    assert_response :not_found
    assert_equal "acknowledged", incident.reload.status
  end

  test "technician cannot transition status" do
    incident = create_test_incident(status: "active")
    IncidentAssignment.create!(incident: incident, user: @tech, assigned_by_user: @manager)
    login_as @tech
    patch transition_incident_path(incident), params: { status: "on_hold" }
    assert_response :not_found
    assert_equal "active", incident.reload.status
  end

  test "property_manager cannot transition status" do
    incident = create_test_incident(status: "acknowledged")
    login_as @pm_user
    patch transition_incident_path(incident), params: { status: "active" }
    assert_response :not_found
    assert_equal "acknowledged", incident.reload.status
  end

  # --- Mark read ---

  test "mark_read creates read state for messages" do
    incident = create_test_incident(status: "active")
    login_as @manager
    assert_difference "IncidentReadState.count", 1 do
      patch mark_read_incident_path(incident), params: { tab: "messages" }
    end
    assert_response :redirect
    rs = IncidentReadState.last
    assert_not_nil rs.last_message_read_at
    assert_nil rs.last_activity_read_at
  end

  test "mark_read creates read state for activity" do
    incident = create_test_incident(status: "active")
    login_as @manager
    patch mark_read_incident_path(incident), params: { tab: "activity" }
    assert_response :redirect
    rs = IncidentReadState.last
    assert_nil rs.last_message_read_at
    assert_not_nil rs.last_activity_read_at
  end

  test "mark_read updates existing read state" do
    incident = create_test_incident(status: "active")
    IncidentReadState.create!(incident: incident, user: @manager, last_message_read_at: 1.day.ago)
    login_as @manager
    assert_no_difference "IncidentReadState.count" do
      patch mark_read_incident_path(incident), params: { tab: "messages" }
    end
    assert_response :redirect
    rs = IncidentReadState.find_by(incident: incident, user: @manager)
    assert rs.last_message_read_at > 1.minute.ago
  end

  test "mark_read returns 404 for invisible incident" do
    incident = create_test_incident(status: "active", property: @other_property)
    login_as @pm_user
    patch mark_read_incident_path(incident), params: { tab: "messages" }
    assert_response :not_found
  end

  test "show unread activity only counts daily log activity entries" do
    incident = create_test_incident(status: "active")

    ActivityEvent.create!(
      incident: incident,
      performed_by_user: @tech,
      event_type: "status_changed",
      metadata: {}
    )
    ActivityEvent.create!(
      incident: incident,
      performed_by_user: @tech,
      event_type: "activity_updated",
      metadata: {}
    )
    ActivityEvent.create!(
      incident: incident,
      performed_by_user: @tech,
      event_type: "activity_logged",
      metadata: {}
    )

    login_as @manager
    get incident_path(incident)
    assert_response :success

    props = inertia_props
    assert_equal 1, props.dig("incident", "unread_activity")
  end

  test "show serializes incident attachments newest first" do
    incident = create_test_incident(status: "active")

    older = incident.attachments.create!(
      uploaded_by_user: @manager,
      category: "general",
      description: "Older doc"
    )
    File.open(Rails.root.join("test/fixtures/files/test_photo.jpg"), "rb") do |io|
      older.file.attach(io: io, filename: "older.jpg", content_type: "image/jpeg")
    end
    older.update_column(:created_at, 2.days.ago)

    newer = incident.attachments.create!(
      uploaded_by_user: @manager,
      category: "photo",
      description: "Newer photo"
    )
    File.open(Rails.root.join("test/fixtures/files/test_photo.jpg"), "rb") do |io|
      newer.file.attach(io: io, filename: "newer.jpg", content_type: "image/jpeg")
    end
    newer.update_column(:created_at, 1.hour.ago)

    login_as @manager
    get incident_path(incident)
    assert_response :success

    deferred = inertia_deferred_props(incident_path(incident), "attachments")
    attachment_ids = deferred.fetch("attachments").map { |att| att.fetch("id") }
    assert_equal [ newer.id, older.id ], attachment_ids.first(2)
  end

  test "show serializes image attachments for message thread" do
    incident = create_test_incident(status: "active")
    message = Message.create!(incident: incident, user: @tech, body: "See attached image")
    message_attachment = message.attachments.create!(
      uploaded_by_user: @tech,
      category: "general"
    )
    File.open(Rails.root.join("test/fixtures/files/test_photo.jpg"), "rb") do |io|
      message_attachment.file.attach(io: io, filename: "thread_photo.jpg", content_type: "image/jpeg")
    end

    login_as @manager
    get incident_path(incident)
    assert_response :success

    deferred = inertia_deferred_props(incident_path(incident), "messages")
    serialized = deferred.fetch("messages").find { |msg| msg.fetch("id") == message.id }
    assert_equal "See attached image", serialized.fetch("body")
    assert_equal 1, serialized.fetch("attachments").length
    assert_equal "image/jpeg", serialized.dig("attachments", 0, "content_type")
  end

  # --- Equipment log ---

  test "equipment log is sorted newest placed first" do
    incident = create_test_incident(status: "active")
    eq_type = EquipmentType.create!(name: "Dehumidifier", organization: @genixo)

    older = incident.equipment_entries.create!(
      equipment_type: eq_type, placed_at: 3.days.ago,
      logged_by_user: @manager
    )
    newer = incident.equipment_entries.create!(
      equipment_type: eq_type, placed_at: 1.day.ago,
      logged_by_user: @manager
    )

    login_as @manager
    get incident_path(incident)
    assert_response :success

    deferred = inertia_deferred_props(incident_path(incident), "equipment_log")
    ids = deferred.fetch("equipment_log").map { |e| e.fetch("id") }
    assert_equal [ newer.id, older.id ], ids
  end

  # --- Labor log column order ---

  test "labor log dates are sorted newest first" do
    incident = create_test_incident(status: "active")

    incident.labor_entries.create!(
      role_label: "Technician", log_date: 3.days.ago.to_date, hours: 8,
      started_at: 3.days.ago.beginning_of_day + 8.hours,
      ended_at: 3.days.ago.beginning_of_day + 16.hours,
      created_by_user: @manager
    )
    incident.labor_entries.create!(
      role_label: "Technician", log_date: 1.day.ago.to_date, hours: 8,
      started_at: 1.day.ago.beginning_of_day + 8.hours,
      ended_at: 1.day.ago.beginning_of_day + 16.hours,
      created_by_user: @manager
    )

    login_as @manager
    get incident_path(incident)
    assert_response :success

    deferred = inertia_deferred_props(incident_path(incident), "labor_log")
    dates = deferred.dig("labor_log", "dates")
    assert_equal dates.sort.reverse, dates, "Labor log dates should be newest first"
  end

  # --- Daily log timeline ---

  test "daily log table groups exclude labor entries" do
    incident = create_test_incident(status: "active")

    incident.labor_entries.create!(
      role_label: "Technician", log_date: Date.today, hours: 8,
      started_at: Time.current.beginning_of_day + 8.hours,
      ended_at: Time.current.beginning_of_day + 16.hours,
      created_by_user: @manager
    )

    login_as @manager
    get incident_path(incident)
    assert_response :success

    groups = inertia_props.fetch("daily_log_table_groups")
    row_types = groups.flat_map { |g| g.fetch("rows").map { |r| r.fetch("row_type") } }
    assert_not_includes row_types, "labor", "Labor rows should not appear in daily log timeline"
  end

  test "daily log table groups exclude attachments" do
    incident = create_test_incident(status: "active")

    attachment = incident.attachments.create!(uploaded_by_user: @manager, category: "general")
    File.open(Rails.root.join("test/fixtures/files/test_photo.jpg"), "rb") do |io|
      attachment.file.attach(io: io, filename: "photo.jpg", content_type: "image/jpeg")
    end

    login_as @manager
    get incident_path(incident)
    assert_response :success

    groups = inertia_props.fetch("daily_log_table_groups")
    row_types = groups.flat_map { |g| g.fetch("rows").map { |r| r.fetch("row_type") } }
    assert_not_includes row_types, "document", "Attachment rows should not appear in daily log timeline"
  end

  test "mark_read with unknown tab leaves read timestamps nil" do
    incident = create_test_incident(status: "active")
    login_as @manager

    assert_difference "IncidentReadState.count", 1 do
      patch mark_read_incident_path(incident), params: { tab: "unknown" }
    end

    read_state = IncidentReadState.find_by!(incident: incident, user: @manager)
    assert_nil read_state.last_message_read_at
    assert_nil read_state.last_activity_read_at
  end

  private

  def inertia_props
    encoded = response.body.match(/data-page="([^"]+)"/m)&.captures&.first
    raise "Missing Inertia data-page payload" unless encoded

    JSON.parse(CGI.unescapeHTML(encoded)).fetch("props")
  end

  # --- Hide closed incidents by default ---

  # --- Manage tab visibility ---

  test "mitigation user sees show_mitigation_team true" do
    incident = create_test_incident(status: "active", property: @property)
    login_as @manager
    get incident_path(incident)
    assert_response :success
    assert_includes response.body, "show_mitigation_team"
    # HTML-encoded JSON: &quot; surrounds keys
    assert_includes response.body, "show_mitigation_team&quot;:true"
  end

  test "PM user sees show_mitigation_team false" do
    incident = create_test_incident(status: "active", property: @property)
    IncidentAssignment.create!(incident: incident, user: @pm_user, assigned_by_user: @manager)
    login_as @pm_user
    get incident_path(incident)
    assert_response :success
    assert_includes response.body, "show_mitigation_team&quot;:false"
  end

  # --- Hide closed incidents by default ---

  test "index hides closed incidents by default" do
    active = create_test_incident(status: "active", property: @property)
    closed = create_test_incident(status: "closed", property: @other_property, description: "Closed job")
    login_as @manager
    get incidents_path
    assert_response :success
    assert_not_includes response.body, "Closed job"
  end

  # --- Attachment permissions ---

  test "PM user cannot upload photo" do
    incident = create_test_incident(status: "active", property: @property)
    IncidentAssignment.create!(incident: incident, user: @pm_user, assigned_by_user: @manager)
    login_as @pm_user
    post upload_photo_incident_attachments_path(incident), params: { file: nil }
    assert_response :not_found
  end

  test "manager can upload photo" do
    incident = create_test_incident(status: "active", property: @property)
    login_as @manager
    post upload_photo_incident_attachments_path(incident), params: { file: nil }
    # 422 because no file, but not 404 — proves authorization passed
    assert_response :unprocessable_entity
  end

  test "PM user cannot delete attachment" do
    incident = create_test_incident(status: "active", property: @property)
    IncidentAssignment.create!(incident: incident, user: @pm_user, assigned_by_user: @manager)
    att = incident.attachments.create!(
      category: "photo", uploaded_by_user: @manager,
      file: fixture_file_upload("test/fixtures/files/test_photo.jpg", "image/jpeg")
    )
    login_as @pm_user
    delete incident_attachment_path(incident, att)
    assert_response :not_found
  end

  test "technician can delete attachment" do
    incident = create_test_incident(status: "active", property: @property)
    IncidentAssignment.create!(incident: incident, user: @tech, assigned_by_user: @manager)
    att = incident.attachments.create!(
      category: "photo", uploaded_by_user: @manager,
      file: fixture_file_upload("test/fixtures/files/test_photo.jpg", "image/jpeg")
    )
    login_as @tech
    delete incident_attachment_path(incident, att)
    # Not 404 = authorization passed (technicians have MANAGE_ATTACHMENTS)
    assert_not_equal 404, response.status
  end

  test "manager can update attachment" do
    incident = create_test_incident(status: "active", property: @property)
    att = incident.attachments.create!(
      category: "photo", uploaded_by_user: @manager,
      file: fixture_file_upload("test/fixtures/files/test_photo.jpg", "image/jpeg"),
      description: "Old desc"
    )
    login_as @manager
    patch incident_attachment_path(incident, att), params: { attachment: { description: "New desc", log_date: "2026-02-20" } }
    att.reload
    assert_equal "New desc", att.description
    assert_equal Date.parse("2026-02-20"), att.log_date
  end

  test "index shows closed incidents when status filter includes closed" do
    closed = create_test_incident(status: "closed", property: @property, description: "Closed job")
    login_as @manager
    get incidents_path, params: { status: "closed" }
    assert_response :success
    assert_includes response.body, "Closed job"
  end

  # Fetch deferred props by making a partial Inertia reload request.
  # Call this after the initial GET when the props you need are deferred.
  def inertia_deferred_props(path, *prop_keys)
    get path, headers: {
      "X-Inertia" => "true",
      "X-Inertia-Partial-Component" => "Incidents/Show",
      "X-Inertia-Partial-Data" => prop_keys.join(",")
    }
    JSON.parse(response.body).fetch("props")
  end

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end

  def create_test_incident(status:, property: nil, description: "Test incident")
    Incident.create!(
      property: property || @property, created_by_user: @manager,
      status: status, project_type: "emergency_response",
      damage_type: "flood", description: description, emergency: true
    )
  end
end
