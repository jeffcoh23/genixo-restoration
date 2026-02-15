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
  LaborEntry.create!(incident: incident1, user: users[:henry], created_by_user: users[:henry],
    role_label: "Technician", log_date: (now - 3.days).to_date, hours: 6.5,
    notes: "Water extraction, equipment setup across units 237-239")

  LaborEntry.create!(incident: incident1, user: users[:zachary], created_by_user: users[:zachary],
    role_label: "Technician", log_date: (now - 3.days).to_date, hours: 5.0,
    notes: "Assisted with extraction, set up containment barriers")

  LaborEntry.create!(incident: incident1, user: users[:henry], created_by_user: users[:henry],
    role_label: "Technician", log_date: (now - 2.days).to_date, hours: 3.0,
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

  # Operational notes
  OperationalNote.create!(incident: incident1, created_by_user: users[:henry],
    note_text: "Extracted approximately 80 gallons of standing water from hallway and units. Set up 6 air movers and 2 dehumidifiers. Carpet in unit 238 may need replacement — pad is saturated. Drywall moisture readings: 238 kitchen 45%, 237 shared wall 28%, 239 shared wall 22%.",
    log_date: (now - 3.days).to_date, created_at: now - 3.days + 6.hours)

  OperationalNote.create!(incident: incident1, created_by_user: users[:henry],
    note_text: "Morning readings showing improvement. 238 kitchen down to 32%, 237 wall 18%, 239 wall 14%. Repositioned 2 air movers for better coverage in 238. Drying progressing well in 237 and 239.",
    log_date: (now - 2.days).to_date, created_at: now - 2.days + 3.hours)

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
    status: "quote_requested",
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
    metadata: { old_status: "new", new_status: "quote_requested" }, created_at: now - 2.days)

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
  LaborEntry.create!(incident: incident3, user: users[:henry], created_by_user: users[:henry],
    role_label: "Technician", log_date: (now - 14.days).to_date, hours: 4.0,
    notes: "Initial assessment, air scrubber setup in 4 units")

  LaborEntry.create!(incident: incident3, user: users[:henry], created_by_user: users[:henry],
    role_label: "Technician", log_date: (now - 13.days).to_date, hours: 8.0,
    notes: "Smoke damage cleaning — unit 305 kitchen and living areas")

  LaborEntry.create!(incident: incident3, user: nil, created_by_user: users[:fred],
    role_label: "General Labor", log_date: (now - 12.days).to_date, hours: 6.0,
    notes: "Surface cleaning units 303, 304, 306")

  LaborEntry.create!(incident: incident3, user: users[:henry], created_by_user: users[:henry],
    role_label: "Technician", log_date: (now - 6.days).to_date, hours: 2.0,
    notes: "Final air quality readings and equipment removal")

  # Equipment — air scrubbers (freeform type, since not in predefined list)
  4.times do |i|
    EquipmentEntry.create!(incident: incident3, equipment_type_other: "Air Scrubber",
      equipment_identifier: "AS-#{300 + i}",
      placed_at: now - 14.days + 5.hours, removed_at: now - 6.days + 3.hours,
      location_notes: "Unit #{303 + i}", logged_by_user: users[:henry])
  end

  # Operational note
  OperationalNote.create!(incident: incident3, created_by_user: users[:henry],
    note_text: "Set up 4 HEPA air scrubbers, one per affected unit. Unit 305 has heavy soot deposits on kitchen ceiling and cabinets — needs chemical sponge cleaning followed by sealing. Other units have light smoke film on walls and ceilings, standard cleaning protocol.",
    log_date: (now - 14.days).to_date, created_at: now - 14.days + 6.hours)

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
