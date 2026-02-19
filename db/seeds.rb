# frozen_string_literal: true

# ==========================================================================
# Genixo Restoration — Seed Data
# ==========================================================================
# Creates a working development environment.
# Run: bin/rails db:seed
# Idempotent: safe to run multiple times.
# ==========================================================================

puts "Seeding database..."

# ==========================================================================
# Organizations
# ==========================================================================

genixo = Organization.find_or_create_by!(name: "Genixo Construction") do |org|
  org.organization_type = "mitigation"
  org.phone = "210-555-0100"
  org.email = "info@genixoconstruction.com"
  org.street_address = "1234 Main St"
  org.city = "San Antonio"
  org.state = "TX"
  org.zip = "78201"
end

greystar = Organization.find_or_create_by!(name: "Greystar Properties") do |org|
  org.organization_type = "property_management"
  org.phone = "713-555-0200"
  org.email = "info@greystar.com"
  org.street_address = "5678 Westheimer Rd"
  org.city = "Houston"
  org.state = "TX"
  org.zip = "77056"
end

sandalwood = Organization.find_or_create_by!(name: "Sandalwood Management") do |org|
  org.organization_type = "property_management"
  org.phone = "512-555-0300"
  org.email = "info@sandalwood.com"
  org.street_address = "910 Congress Ave"
  org.city = "Austin"
  org.state = "TX"
  org.zip = "78701"
end

puts "  Organizations: #{Organization.count}"

# ==========================================================================
# Users — Genixo Construction (Mitigation)
# ==========================================================================
# Source: Employee Contact Information spreadsheet
# Categorization: VP/Director/PM → manager, Supervisor → technician,
#                 Office/Estimating/BD → office_sales

genixo_user_data = [
  # Managers (7)
  { key: :fred,     first_name: "Fred",     last_name: "Hall",    email_address: "fhall@genixoconstruction.com",   user_type: "manager",   phone: "210-763-2025" },
  { key: :daniel,   first_name: "Daniel",   last_name: "Hutson",  email_address: "dhutson@genixoconstruction.com", user_type: "manager",   phone: "830-463-9104" },
  { key: :caleb,    first_name: "Caleb",    last_name: "Miller",  email_address: "cmiller@genixoconstruction.com", user_type: "manager",   phone: nil },
  { key: :jeremy,   first_name: "Jeremy",   last_name: "Owen",    email_address: "jowen@genixoconstruction.com",   user_type: "manager",   phone: "832-797-8773" },
  { key: :john,     first_name: "John",     last_name: "Tucker",  email_address: "jtucker@genixoconstruction.com", user_type: "manager",   phone: "657-414-9166" },
  { key: :anthony,  first_name: "Anthony",  last_name: "Wagner",  email_address: "awagner@genixoconstruction.com", user_type: "manager",   phone: "405-742-7066" },
  { key: :gordon,   first_name: "Gordon",   last_name: "Ward",    email_address: "gward@genixoconstruction.com",   user_type: "manager",   phone: "210-777-8686" },
  # Technicians (2)
  { key: :henry,    first_name: "Henry",    last_name: "Tello",   email_address: "htello@genixoconstruction.com",  user_type: "technician", phone: "346-412-8623" },
  { key: :zachary,  first_name: "Zachary",  last_name: "Meyer",   email_address: "zmeyer@genixoconstruction.com",  user_type: "technician", phone: "512-308-8872" },
  # Office/Sales (5)
  { key: :chrystie, first_name: "Chrystie", last_name: "Butler",  email_address: "cbutler@genixoconstruction.com", user_type: "office_sales", phone: "281-825-1725" },
  { key: :emily,    first_name: "Emily",    last_name: "Northern", email_address: "enorthern@genixoconstruction.com", user_type: "office_sales", phone: "512-364-2369" },
  { key: :melanie,  first_name: "Melanie",  last_name: "Woods",   email_address: "mwoods@genixoconstruction.com", user_type: "office_sales", phone: "979-595-5224" },
  { key: :taylor,   first_name: "Taylor",   last_name: "Kasbohm", email_address: "tkasbohm@genixoconstruction.com", user_type: "office_sales", phone: "210-440-0606" },
  { key: :jessica,  first_name: "Jessica",  last_name: "Sedita",  email_address: "jsedita@genixoconstruction.com", user_type: "office_sales", phone: "936-276-1326" }
]

users = {}

genixo_user_data.each do |data|
  key = data.delete(:key)
  users[key] = User.find_or_create_by!(organization: genixo, email_address: data[:email_address]) do |u|
    u.assign_attributes(data.merge(password: "password", timezone: "America/Chicago"))
  end
end

# ==========================================================================
# Users — Greystar Properties (PM)
# ==========================================================================

users[:jane] = User.find_or_create_by!(organization: greystar, email_address: "jane@greystar.com") do |u|
  u.first_name = "Jane"
  u.last_name = "Smith"
  u.user_type = "property_manager"
  u.phone = "713-555-0201"
  u.password = "password"
  u.timezone = "America/Chicago"
end

users[:tom] = User.find_or_create_by!(organization: greystar, email_address: "tom@greystar.com") do |u|
  u.first_name = "Tom"
  u.last_name = "Rodriguez"
  u.user_type = "area_manager"
  u.phone = "713-555-0202"
  u.password = "password"
  u.timezone = "America/Chicago"
end

users[:amy] = User.find_or_create_by!(organization: greystar, email_address: "amy@greystar.com") do |u|
  u.first_name = "Amy"
  u.last_name = "Chen"
  u.user_type = "pm_manager"
  u.phone = "713-555-0203"
  u.password = "password"
  u.timezone = "America/Chicago"
end

# ==========================================================================
# Users — Sandalwood Management (PM isolation test)
# ==========================================================================

users[:bob] = User.find_or_create_by!(organization: sandalwood, email_address: "bob@sandalwood.com") do |u|
  u.first_name = "Bob"
  u.last_name = "Johnson"
  u.user_type = "property_manager"
  u.phone = "512-555-0301"
  u.password = "password"
  u.timezone = "America/Chicago"
end

puts "  Users: #{User.count}"

# ==========================================================================
# Properties
# ==========================================================================

park_river_oaks = Property.find_or_create_by!(name: "Park at River Oaks") do |p|
  p.property_management_org = greystar
  p.mitigation_org = genixo
  p.street_address = "2200 Willowick Rd"
  p.city = "Houston"
  p.state = "TX"
  p.zip = "77027"
  p.unit_count = 312
end

greystar_heights = Property.find_or_create_by!(name: "Greystar Heights") do |p|
  p.property_management_org = greystar
  p.mitigation_org = genixo
  p.street_address = "4500 Montrose Blvd"
  p.city = "Houston"
  p.state = "TX"
  p.zip = "77006"
  p.unit_count = 248
end

sandalwood_apts = Property.find_or_create_by!(name: "Sandalwood Apartments") do |p|
  p.property_management_org = sandalwood
  p.mitigation_org = genixo
  p.street_address = "7800 Shoal Creek Blvd"
  p.city = "Austin"
  p.state = "TX"
  p.zip = "78757"
  p.unit_count = 180
end

puts "  Properties: #{Property.count}"

# ==========================================================================
# Property Assignments
# ==========================================================================

{
  jane: [ park_river_oaks ],
  tom:  [ park_river_oaks, greystar_heights ],
  amy:  [ park_river_oaks, greystar_heights ],
  bob:  [ sandalwood_apts ]
}.each do |user_key, properties|
  properties.each do |property|
    PropertyAssignment.find_or_create_by!(user: users[user_key], property: property)
  end
end

puts "  Property Assignments: #{PropertyAssignment.count}"

# ==========================================================================
# Equipment Types (Genixo org)
# ==========================================================================

equipment_types = {}
[ "Dehumidifier", "Air Mover", "Air Blower", "Water Extraction Unit" ].each do |name|
  equipment_types[name] = EquipmentType.find_or_create_by!(organization: genixo, name: name)
end

puts "  Equipment Types: #{EquipmentType.count}"

# ==========================================================================
# On-Call Configuration (Genixo org)
# ==========================================================================

on_call = OnCallConfiguration.find_or_create_by!(organization: genixo) do |config|
  config.primary_user = users[:fred]
  config.escalation_timeout_minutes = 10
end

EscalationContact.find_or_create_by!(on_call_configuration: on_call, position: 1) do |c|
  c.user = users[:daniel]
end

EscalationContact.find_or_create_by!(on_call_configuration: on_call, position: 2) do |c|
  c.user = users[:anthony]
end

puts "  On-Call Config: #{OnCallConfiguration.count} (#{EscalationContact.count} escalation contacts)"

# ==========================================================================
# Sample Incidents
# ==========================================================================
# Only created on first seed run (too complex for field-level idempotency).

if Incident.count.zero?
  now = Time.current

  # Helper: auto-assign users per BUSINESS_RULES.md §5
  auto_assign = lambda do |incident, creator, property|
    assigned = []

    # All managers + office_sales in the mitigation org
    User.where(organization: genixo, user_type: %w[manager office_sales], active: true).find_each do |u|
      assigned << u
    end

    # PM users assigned to this property
    property.assigned_users.where(active: true).find_each do |u|
      assigned << u
    end

    # pm_managers in the PM org (auto-assigned to all incidents in their org)
    User.where(organization: property.property_management_org, user_type: "pm_manager", active: true).find_each do |u|
      assigned << u unless assigned.include?(u)
    end

    assigned.uniq.each do |u|
      IncidentAssignment.create!(incident: incident, user: u, assigned_by_user: creator)
    end
  end

  # --------------------------------------------------------------------------
  # Incident 1: Active emergency flood at Park at River Oaks
  # --------------------------------------------------------------------------

  incident1 = Incident.create!(
    property: park_river_oaks,
    created_by_user: users[:jane],
    status: "active",
    project_type: "emergency_response",
    emergency: true,
    damage_type: "flood",
    description: "Major water leak from unit 238 supply line rupture. Water has spread to units 237, 239, and the hallway. Carpet, drywall, and baseboards affected. Residents have been temporarily relocated.",
    cause: "Supply line burst in unit 238 kitchen",
    requested_next_steps: "Immediate water extraction and drying. Please assess all affected units.",
    units_affected: 3,
    affected_room_numbers: "237, 238, 239",
    last_activity_at: now - 2.hours,
    created_at: now - 3.days
  )

  auto_assign.call(incident1, users[:jane], park_river_oaks)

  # Assign technicians (done by manager after moving to active)
  [ :henry, :zachary ].each do |tech|
    IncidentAssignment.create!(incident: incident1, user: users[tech], assigned_by_user: users[:fred])
  end

  # Activity timeline
  ActivityEvent.create!(incident: incident1, event_type: "incident_created", performed_by_user: users[:jane],
    metadata: { project_type: "emergency_response", damage_type: "flood" }, created_at: now - 3.days)

  ActivityEvent.create!(incident: incident1, event_type: "status_changed", performed_by_user: users[:jane],
    metadata: { old_status: "new", new_status: "acknowledged" }, created_at: now - 3.days)

  ActivityEvent.create!(incident: incident1, event_type: "status_changed", performed_by_user: users[:fred],
    metadata: { old_status: "acknowledged", new_status: "active" }, created_at: now - 3.days + 30.minutes)

  [ :henry, :zachary ].each do |tech|
    ActivityEvent.create!(incident: incident1, event_type: "user_assigned", performed_by_user: users[:fred],
      metadata: { user_id: users[tech].id, user_name: users[tech].full_name, user_type: "technician" },
      created_at: now - 3.days + 45.minutes)
  end

  # Messages
  [
    { user: :jane,  body: "Water is actively flowing from unit 238. Maintenance has shut off the main supply to that unit but there's significant standing water in the hallway.", at: now - 3.days },
    { user: :fred,  body: "Team is en route. ETA 25 minutes. We'll start with extraction in the hallway and work into the units. Henry and Zachary will be on site.", at: now - 3.days + 15.minutes },
    { user: :henry, body: "On site now. Started water extraction in hallway. Standing water is about 1/2 inch deep. Moving into unit 238 next.", at: now - 3.days + 1.hour },
    { user: :henry, body: "Extraction complete. Placed 6 air movers and 2 dehumidifiers across the three units. Will check moisture readings tomorrow morning.", at: now - 3.days + 4.hours },
    { user: :jane,  body: "Thank you for the quick response. Residents in 237 and 239 are asking about timeline — when do you think they can return?", at: now - 2.days },
    { user: :fred,  body: "Based on initial assessment, we're looking at 3-4 days of drying minimum. We'll have a better estimate after tomorrow's moisture readings.", at: now - 2.days + 2.hours }
  ].each do |msg|
    Message.create!(incident: incident1, user: users[msg[:user]], body: msg[:body], created_at: msg[:at])
  end

  # Labor entries
  day3 = (now - 3.days).to_date
  day2 = (now - 2.days).to_date

  LaborEntry.create!(incident: incident1, user: users[:henry], created_by_user: users[:henry],
    role_label: "Technician", log_date: day3, hours: 6.5,
    started_at: day3.beginning_of_day + 8.hours, ended_at: day3.beginning_of_day + 14.hours + 30.minutes,
    notes: "Water extraction, equipment setup across units 237-239")

  LaborEntry.create!(incident: incident1, user: users[:zachary], created_by_user: users[:zachary],
    role_label: "Technician", log_date: day3, hours: 5.0,
    started_at: day3.beginning_of_day + 9.hours, ended_at: day3.beginning_of_day + 14.hours,
    notes: "Assisted with extraction, set up containment barriers")

  LaborEntry.create!(incident: incident1, user: users[:henry], created_by_user: users[:henry],
    role_label: "Technician", log_date: day2, hours: 3.0,
    started_at: day2.beginning_of_day + 7.hours, ended_at: day2.beginning_of_day + 10.hours,
    notes: "Morning moisture readings, adjusted equipment positioning")

  # Equipment entries
  6.times do |i|
    location = case i
    when 0..1 then "Unit 237, living room"
    when 2..3 then "Unit 238, kitchen and hallway"
    else "Unit 239, bedroom"
    end
    EquipmentEntry.create!(incident: incident1, equipment_type: equipment_types["Air Mover"],
      equipment_identifier: "AM-#{100 + i}", placed_at: now - 3.days + 3.hours,
      location_notes: location, logged_by_user: users[:henry])
  end

  2.times do |i|
    EquipmentEntry.create!(incident: incident1, equipment_type: equipment_types["Dehumidifier"],
      equipment_identifier: "DH-#{200 + i}", placed_at: now - 3.days + 3.hours,
      location_notes: i.zero? ? "Unit 238, living room" : "Hallway between 237-239",
      logged_by_user: users[:henry])
  end

  # Activity entries — DFR-style daily logs with rich per-unit narratives
  # Day 1: Initial response
  day1 = ActivityEntry.create!(
    incident: incident1,
    performed_by_user: users[:henry],
    title: "Initial response and water extraction",
    details: "237 – Water intrusion from adjacent unit 238 through shared kitchen wall. Standing water found in kitchen and living room. Carpet is saturated along the shared wall approximately 8 feet out. Removed baseboards along shared wall, drilled weep holes in drywall at 16\" intervals. Extracted bulk water with truck-mounted extractor and set up drying equipment.\n\n238 – Source unit. Supply line burst under kitchen sink caused significant flooding throughout the unit. Standing water in kitchen, hallway, and living room — approximately 1\" deep in kitchen. Carpet pad is saturated throughout. Removed all baseboards, drilled weep holes, performed full extraction. This unit will require the longest drying time due to severity.\n\n239 – Minor water intrusion through shared hallway wall. Affected area limited to approximately 4 feet along the hallway-side bedroom wall. Removed baseboards in affected area, drilled weep holes, extracted standing water. Damage appears contained.\n\nHallway – Standing water found in the hallway between all three units. Extracted approximately 30 gallons. Hallway carpet may need replacement — pad is heavily saturated and water has reached the subfloor in spots.",
    units_affected: 3,
    units_affected_description: "Units 237, 238, 239 plus hallway",
    visitors: "Safety walkthrough",
    usable_rooms_returned: "None",
    estimated_date_of_return: now + 4.days,
    status: "completed",
    occurred_at: now - 3.days + 8.hours
  )

  ActivityEquipmentAction.create!(activity_entry: day1, action_type: "add", quantity: 6,
    equipment_type: equipment_types["Air Mover"], note: "2 per unit for primary dry-down pass")
  ActivityEquipmentAction.create!(activity_entry: day1, action_type: "add", quantity: 2,
    equipment_type: equipment_types["Dehumidifier"], note: "1 in unit 238, 1 in hallway")

  ActivityEvent.create!(incident: incident1, event_type: "activity_logged",
    performed_by_user: users[:henry], metadata: { title: day1.title, status: day1.status },
    created_at: day1.occurred_at)

  # Day 2: Progress check and equipment adjustment
  day2 = ActivityEntry.create!(
    incident: incident1,
    performed_by_user: users[:henry],
    title: "Moisture readings and equipment adjustment",
    details: "237 – Morning moisture readings: kitchen shared wall 28%, living room wall 18%. Drying is progressing well. Kitchen wall is the slowest area — added 1 additional air mover focused on this section. Carpet pad readings improved to acceptable levels; carpet itself may be salvageable.\n\n238 – Morning moisture readings: kitchen 45%, hallway 32%, living room 28%. This unit is still significantly elevated. Kitchen subfloor reading at 38% — may have plywood damage. Repositioned 2 air movers for better coverage on kitchen cabinets and hallway. Added 1 additional dehumidifier from storage.\n\n239 – Morning moisture readings: bedroom wall 14%, hallway side 12%. This unit is nearly dry. Will check again tomorrow and likely remove equipment if readings continue to drop.\n\nHallway – Carpet readings at 22%. Subfloor appears intact. Drying on schedule.",
    units_affected: 3,
    units_affected_description: "Units 237, 238, 239 plus hallway",
    usable_rooms_returned: "None",
    estimated_date_of_return: now + 3.days,
    status: "completed",
    occurred_at: now - 2.days + 8.hours
  )

  ActivityEquipmentAction.create!(activity_entry: day2, action_type: "add", quantity: 1,
    equipment_type: equipment_types["Air Mover"], note: "Added to unit 237 kitchen shared wall")
  ActivityEquipmentAction.create!(activity_entry: day2, action_type: "add", quantity: 1,
    equipment_type: equipment_types["Dehumidifier"], note: "Added to unit 238 from storage")
  ActivityEquipmentAction.create!(activity_entry: day2, action_type: "move", quantity: 2,
    equipment_type: equipment_types["Air Mover"], note: "Repositioned in unit 238 for kitchen/hallway coverage")

  ActivityEvent.create!(incident: incident1, event_type: "activity_logged",
    performed_by_user: users[:henry], metadata: { title: day2.title, status: day2.status },
    created_at: day2.occurred_at)

  # Day 3: Continued drying, unit 239 cleared
  day3 = ActivityEntry.create!(
    incident: incident1,
    performed_by_user: users[:henry],
    title: "Continued drying — unit 239 cleared",
    details: "237 – Moisture readings: kitchen shared wall down to 18%, living room 12%. Good progress. Carpet pad readings now at acceptable levels in all areas. Will continue drying one more day to ensure wall cavities are fully dry.\n\n238 – Moisture readings: kitchen 32%, hallway 22%, living room 18%. Kitchen is still elevated but improving steadily. Subfloor reading down to 28%. Cabinet toe kicks still showing moisture — pulled bottom shelf items out to improve airflow behind cabinets. Carpet pad in this unit will need full replacement — too saturated to salvage.\n\n239 – All readings below 15%. Unit is dry. Removed all equipment from this unit. Baseboards can be reinstalled once painting is complete. Recommend new baseboards for the 4-foot affected section.\n\nHallway – Readings at 16%. Nearly dry. Carpet pad may be salvageable here.",
    units_affected: 2,
    units_affected_description: "Units 237, 238 (239 cleared)",
    usable_rooms_returned: "Unit 239",
    estimated_date_of_return: now + 2.days,
    status: "in_progress",
    occurred_at: now - 1.day + 8.hours
  )

  ActivityEquipmentAction.create!(activity_entry: day3, action_type: "remove", quantity: 2,
    equipment_type: equipment_types["Air Mover"], note: "Removed from unit 239 — unit is dry")

  ActivityEvent.create!(incident: incident1, event_type: "activity_logged",
    performed_by_user: users[:henry], metadata: { title: day3.title, status: day3.status },
    created_at: day3.occurred_at)

  # Note: Operational notes are not used — all DFR content is captured in activity entry details.

  # Incident contact
  IncidentContact.create!(incident: incident1, name: "Patricia Williams", title: "Insurance Adjuster",
    email: "pwilliams@stateinsurance.com", phone: "713-555-0999", created_by_user: users[:fred])

  puts "  Incident 1 (Emergency Flood — Active): created"

  # --------------------------------------------------------------------------
  # Incident 2: Quote requested — mold at Greystar Heights
  # --------------------------------------------------------------------------

  incident2 = Incident.create!(
    property: greystar_heights,
    created_by_user: users[:tom],
    status: "proposal_requested",
    project_type: "mitigation_rfq",
    emergency: false,
    damage_type: "mold",
    description: "Mold discovered during routine HVAC inspection in units 112 and 114. Visible mold growth on HVAC ductwork and adjacent drywall. No active water leak found — may be condensation-related.",
    cause: "Suspected condensation buildup in HVAC system",
    requested_next_steps: "Please provide quote for mold remediation of affected ductwork and drywall in both units.",
    units_affected: 2,
    affected_room_numbers: "112, 114",
    last_activity_at: now - 1.day,
    created_at: now - 2.days
  )

  auto_assign.call(incident2, users[:tom], greystar_heights)

  ActivityEvent.create!(incident: incident2, event_type: "incident_created", performed_by_user: users[:tom],
    metadata: { project_type: "mitigation_rfq", damage_type: "mold" }, created_at: now - 2.days)

  ActivityEvent.create!(incident: incident2, event_type: "status_changed", performed_by_user: users[:tom],
    metadata: { old_status: "new", new_status: "proposal_requested" }, created_at: now - 2.days)

  [
    { user: :tom,    body: "Photos attached from the HVAC inspection. The mold is concentrated around the supply vents in both units. Residents haven't reported any health issues yet but we'd like to get this handled quickly.", at: now - 2.days },
    { user: :gordon, body: "Thanks Tom. I'll schedule a site visit for tomorrow to assess the scope. We'll have a quote to you within 48 hours of the walkthrough.", at: now - 2.days + 3.hours }
  ].each do |msg|
    Message.create!(incident: incident2, user: users[msg[:user]], body: msg[:body], created_at: msg[:at])
  end

  puts "  Incident 2 (Mold RFQ — Quote Requested): created"

  # --------------------------------------------------------------------------
  # Incident 3: Completed smoke damage at Park at River Oaks
  # --------------------------------------------------------------------------

  incident3 = Incident.create!(
    property: park_river_oaks,
    created_by_user: users[:jane],
    status: "completed",
    project_type: "emergency_response",
    emergency: false,
    damage_type: "smoke",
    description: "Kitchen fire in unit 305. Fire department responded and extinguished. Smoke damage to unit 305 and adjacent units 303, 304, 306. No structural damage reported.",
    cause: "Unattended cooking in unit 305",
    requested_next_steps: "Smoke damage assessment and cleanup for all affected units.",
    units_affected: 4,
    affected_room_numbers: "303, 304, 305, 306",
    last_activity_at: now - 5.days,
    created_at: now - 14.days
  )

  auto_assign.call(incident3, users[:jane], park_river_oaks)
  IncidentAssignment.create!(incident: incident3, user: users[:henry], assigned_by_user: users[:fred])

  # Full status progression
  ActivityEvent.create!(incident: incident3, event_type: "incident_created", performed_by_user: users[:jane],
    metadata: { project_type: "emergency_response", damage_type: "smoke" }, created_at: now - 14.days)

  ActivityEvent.create!(incident: incident3, event_type: "status_changed", performed_by_user: users[:jane],
    metadata: { old_status: "new", new_status: "acknowledged" }, created_at: now - 14.days)

  ActivityEvent.create!(incident: incident3, event_type: "status_changed", performed_by_user: users[:fred],
    metadata: { old_status: "acknowledged", new_status: "active" }, created_at: now - 14.days + 1.hour)

  ActivityEvent.create!(incident: incident3, event_type: "user_assigned", performed_by_user: users[:fred],
    metadata: { user_id: users[:henry].id, user_name: users[:henry].full_name, user_type: "technician" },
    created_at: now - 14.days + 1.hour)

  ActivityEvent.create!(incident: incident3, event_type: "status_changed", performed_by_user: users[:fred],
    metadata: { old_status: "active", new_status: "completed" }, created_at: now - 5.days)

  # Messages
  [
    { user: :jane,  body: "Fire department cleared the building about an hour ago. Units 303-306 all have visible smoke damage. Unit 305 has the worst — kitchen is heavily affected.", at: now - 14.days },
    { user: :fred,  body: "Henry is headed over now for assessment. We'll get started on air scrubbing today and do a full scope tomorrow.", at: now - 14.days + 2.hours },
    { user: :henry, body: "Assessment complete. Unit 305 needs full cleaning — walls, ceiling, cabinets. Units 303, 304, 306 have moderate smoke residue. Setting up air scrubbers in all four units now.", at: now - 14.days + 5.hours },
    { user: :fred,  body: "All work completed. Final air quality readings are within normal range across all four units. Sending completion report.", at: now - 5.days }
  ].each do |msg|
    Message.create!(incident: incident3, user: users[msg[:user]], body: msg[:body], created_at: msg[:at])
  end

  # Labor
  d14 = (now - 14.days).to_date
  d13 = (now - 13.days).to_date
  d12 = (now - 12.days).to_date
  d6 = (now - 6.days).to_date

  LaborEntry.create!(incident: incident3, user: users[:henry], created_by_user: users[:henry],
    role_label: "Technician", log_date: d14, hours: 4.0,
    started_at: d14.beginning_of_day + 8.hours, ended_at: d14.beginning_of_day + 12.hours,
    notes: "Initial assessment, air scrubber setup in 4 units")

  LaborEntry.create!(incident: incident3, user: users[:henry], created_by_user: users[:henry],
    role_label: "Technician", log_date: d13, hours: 8.0,
    started_at: d13.beginning_of_day + 7.hours, ended_at: d13.beginning_of_day + 15.hours,
    notes: "Smoke damage cleaning — unit 305 kitchen and living areas")

  LaborEntry.create!(incident: incident3, user: nil, created_by_user: users[:fred],
    role_label: "General Labor", log_date: d12, hours: 6.0,
    started_at: d12.beginning_of_day + 8.hours, ended_at: d12.beginning_of_day + 14.hours,
    notes: "Surface cleaning units 303, 304, 306")

  LaborEntry.create!(incident: incident3, user: users[:henry], created_by_user: users[:henry],
    role_label: "Technician", log_date: d6, hours: 2.0,
    started_at: d6.beginning_of_day + 9.hours, ended_at: d6.beginning_of_day + 11.hours,
    notes: "Final air quality readings and equipment removal")

  # Equipment — air scrubbers (freeform type, since not in predefined list)
  4.times do |i|
    EquipmentEntry.create!(incident: incident3, equipment_type_other: "Air Scrubber",
      equipment_identifier: "AS-#{300 + i}",
      placed_at: now - 14.days + 5.hours, removed_at: now - 6.days + 3.hours,
      location_notes: "Unit #{303 + i}", logged_by_user: users[:henry])
  end

  # Activity entries — DFR-style daily logs for smoke damage
  smoke_day1 = ActivityEntry.create!(
    incident: incident3,
    performed_by_user: users[:henry],
    title: "Initial assessment and air scrubber setup",
    details: "305 – Source unit. Kitchen fire caused heavy soot and smoke damage throughout. Kitchen ceiling is blackened with thick soot deposits. Cabinets have smoke film and grease residue. Living room and bedroom have moderate smoke residue on walls and ceiling. HVAC system was running during the fire and distributed smoke throughout the unit. Sealed off HVAC vents to prevent further contamination. Set up HEPA air scrubber in the kitchen area. This unit will require chemical sponge cleaning on all surfaces, followed by sealing primer before repainting.\n\n303 – Light smoke film on bedroom ceiling and living room walls adjacent to unit 305. Smoke entered primarily through shared wall penetrations and HVAC system. Set up air scrubber in the living room. Standard cleaning protocol should be sufficient.\n\n304 – Moderate smoke residue on kitchen and living room walls. Stronger odor than 303, likely due to proximity to 305's kitchen. Some soot deposits visible on kitchen ceiling near shared wall. Set up air scrubber. Will need chemical sponge cleaning on the kitchen ceiling, standard wipe-down elsewhere.\n\n306 – Light smoke film similar to 303. Affected areas are the bedroom and hallway adjacent to 305. Set up air scrubber. Standard cleaning protocol.",
    units_affected: 4,
    units_affected_description: "Units 303, 304, 305, 306",
    visitors: "Fire department follow-up inspection",
    usable_rooms_returned: "None",
    estimated_date_of_return: now - 5.days,
    status: "completed",
    occurred_at: now - 14.days + 9.hours
  )

  smoke_day2 = ActivityEntry.create!(
    incident: incident3,
    performed_by_user: users[:henry],
    title: "Full cleaning — unit 305 kitchen and common areas",
    details: "305 – Began intensive cleaning. Kitchen ceiling chemical sponge cleaning completed — required three passes to remove soot deposits. Started on cabinet exteriors and interior shelving. HVAC ductwork in this unit needs professional duct cleaning before system can be used. Living room walls cleaned with standard smoke residue removal solution. Bedroom deferred to tomorrow.\n\n303 – Completed all cleaning. Walls and ceiling wiped down, air quality readings improved significantly. Air scrubber will continue running overnight.\n\n304 – Kitchen ceiling chemical sponge cleaning completed. Living room walls wiped down. Moderate smoke odor persists — will continue air scrubbing and reassess tomorrow.\n\n306 – Completed all cleaning. Similar to 303 — light residue removed with standard protocol. Air scrubber running overnight.",
    units_affected: 4,
    units_affected_description: "Units 303, 304, 305, 306",
    usable_rooms_returned: "None",
    status: "completed",
    occurred_at: now - 13.days + 8.hours
  )

  smoke_day3 = ActivityEntry.create!(
    incident: incident3,
    performed_by_user: users[:henry],
    title: "Final cleaning and equipment removal",
    details: "305 – Completed bedroom cleaning and second pass on kitchen cabinets. Applied sealing primer to kitchen ceiling and walls. All surfaces clean and sealed. Air quality readings within normal range. HVAC duct cleaning scheduled separately by building management. Equipment removed.\n\n303 – Final air quality check — all readings normal. Equipment removed. Unit cleared for occupancy.\n\n304 – Second cleaning pass on kitchen. Smoke odor has dissipated after 48 hours of air scrubbing. Air quality readings normal. Equipment removed. Unit cleared for occupancy.\n\n306 – Final air quality check — all readings normal. Equipment removed. Unit cleared for occupancy.",
    units_affected: 4,
    units_affected_description: "Units 303, 304, 305, 306",
    usable_rooms_returned: "303, 304, 306",
    estimated_date_of_return: now - 4.days,
    status: "completed",
    occurred_at: now - 12.days + 8.hours
  )

  [smoke_day1, smoke_day2, smoke_day3].each do |entry|
    ActivityEvent.create!(incident: incident3, event_type: "activity_logged",
      performed_by_user: users[:henry], metadata: { title: entry.title, status: entry.status },
      created_at: entry.occurred_at)
  end

  # Note: Operational notes are not used — all DFR content is captured in activity entry details.

  puts "  Incident 3 (Smoke Damage — Completed): created"
end

# ==========================================================================
# Summary
# ==========================================================================

puts ""
puts "Seed complete!"
puts "  #{Organization.count} organizations"
puts "  #{User.count} users (password: 'password' for all)"
puts "  #{Property.count} properties"
puts "  #{PropertyAssignment.count} property assignments"
puts "  #{EquipmentType.count} equipment types"
puts "  #{Incident.count} incidents"
puts "  #{Message.count} messages"
puts "  #{LaborEntry.count} labor entries"
puts "  #{EquipmentEntry.count} equipment entries"
puts "  #{ActivityEvent.count} activity events"
