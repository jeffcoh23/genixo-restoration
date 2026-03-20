# frozen_string_literal: true

# Creates an isolated demo environment for Apple App Store review.
# Separate orgs, users, properties, and incidents — no overlap with real data.
# Run:   bin/rails demo:setup
# Safe to run multiple times — tears down and recreates demo data.

namespace :demo do
  DEMO_PASSWORD = "GenixoDemo2026!"
  DEMO_MIT_EMAIL = "demo@genixorestoration.com"
  DEMO_ORG_PREFIX = "[DEMO]"

  desc "Create isolated demo environment for Apple App Store review"
  task setup: :environment do
    puts "Setting up demo environment..."

    teardown_existing!

    now = Time.current

    # ========================================================================
    # Organizations
    # ========================================================================
    mit_org = Organization.create!(
      name: "#{DEMO_ORG_PREFIX} Summit Restoration",
      organization_type: "mitigation",
      phone: "512-555-0800",
      email: "info@summitrestoration.example",
      street_address: "900 Congress Ave",
      city: "Austin",
      state: "TX",
      zip: "78701"
    )

    pm_org = Organization.create!(
      name: "#{DEMO_ORG_PREFIX} Parkview Properties",
      organization_type: "property_management",
      phone: "713-555-0900",
      email: "info@parkviewproperties.example",
      street_address: "2400 Post Oak Blvd",
      city: "Houston",
      state: "TX",
      zip: "77056"
    )

    puts "  Organizations: 2"

    # ========================================================================
    # Users
    # ========================================================================
    reviewer = create_user!(mit_org, DEMO_MIT_EMAIL, "Alex", "Morgan", User::MANAGER, "512-555-0801")
    tech1    = create_user!(mit_org, "demo.tech1@summitrestoration.example", "Marcus", "Rivera", User::TECHNICIAN, "512-555-0802")
    tech2    = create_user!(mit_org, "demo.tech2@summitrestoration.example", "Sarah", "Chen", User::TECHNICIAN, "512-555-0803")
    office   = create_user!(mit_org, "demo.office@summitrestoration.example", "Jordan", "Blake", User::OFFICE_SALES, "512-555-0804")

    pm1 = create_user!(pm_org, "demo.pm1@parkviewproperties.example", "Lisa", "Torres", "property_manager", "713-555-0901")
    pm2 = create_user!(pm_org, "demo.pm2@parkviewproperties.example", "Kevin", "Park", "area_manager", "713-555-0902")

    puts "  Users: 6"

    # ========================================================================
    # Equipment Types
    # ========================================================================
    eq_dehumidifier = EquipmentType.create!(organization: mit_org, name: "Dehumidifier")
    eq_air_mover    = EquipmentType.create!(organization: mit_org, name: "Air Mover")
    eq_air_scrubber = EquipmentType.create!(organization: mit_org, name: "Air Scrubber")

    # ========================================================================
    # Properties
    # ========================================================================
    lakewood = Property.create!(
      name: "Lakewood Terrace",
      property_management_org: pm_org,
      mitigation_org: mit_org,
      street_address: "4200 Lakewood Blvd",
      city: "Houston",
      state: "TX",
      zip: "77098",
      unit_count: 220
    )

    cedar_ridge = Property.create!(
      name: "Cedar Ridge Apartments",
      property_management_org: pm_org,
      mitigation_org: mit_org,
      street_address: "1850 Cedar Springs Rd",
      city: "Dallas",
      state: "TX",
      zip: "75201",
      unit_count: 156
    )

    magnolia = Property.create!(
      name: "Magnolia Gardens",
      property_management_org: pm_org,
      mitigation_org: mit_org,
      street_address: "3100 Magnolia St",
      city: "San Antonio",
      state: "TX",
      zip: "78201",
      unit_count: 88
    )

    # Property assignments
    [pm1, pm2].each do |pm_user|
      [lakewood, cedar_ridge, magnolia].each do |prop|
        PropertyAssignment.create!(user: pm_user, property: prop)
      end
    end

    puts "  Properties: 3"

    # ========================================================================
    # Incident 1: Active emergency — water damage at Lakewood Terrace
    # ========================================================================
    i1 = Incident.create!(
      property: lakewood,
      created_by_user: pm1,
      status: "active",
      project_type: "emergency_response",
      emergency: true,
      damage_type: "flood",
      description: "Major water leak from unit 305 supply line rupture. Water has spread to units 304, 306, and the third-floor hallway. Carpet, drywall, and baseboards all affected. Three residents have been temporarily relocated.",
      cause: "Supply line burst in unit 305 kitchen",
      requested_next_steps: "Immediate water extraction and drying. Assess all affected units and provide timeline for resident return.",
      units_affected: 3,
      affected_room_numbers: "304, 305, 306",
      last_activity_at: now - 4.hours,
      created_at: now - 2.days
    )

    [reviewer, tech1, tech2].each do |u|
      IncidentAssignment.create!(incident: i1, user: u, assigned_by_user: reviewer)
    end
    IncidentAssignment.create!(incident: i1, user: pm1, assigned_by_user: pm1)

    ActivityEvent.create!(incident: i1, event_type: "incident_created", performed_by_user: pm1,
      metadata: { project_type: "emergency_response", damage_type: "flood" }, created_at: now - 2.days)
    ActivityEvent.create!(incident: i1, event_type: "status_changed", performed_by_user: reviewer,
      metadata: { old_status: "new", new_status: "active" }, created_at: now - 2.days + 30.minutes)

    [
      { user: pm1,     body: "Water is actively flowing from unit 305. Maintenance shut off the main supply but there's significant standing water in the hallway.", at: now - 2.days },
      { user: reviewer, body: "Team is en route. Marcus and Sarah will be on site within 30 minutes. Starting with extraction in the hallway.", at: now - 2.days + 20.minutes },
      { user: tech1,   body: "On site now. Started water extraction in hallway. Standing water is about half an inch deep. Moving into unit 305 next.", at: now - 2.days + 1.hour },
      { user: tech1,   body: "Extraction complete in all three units. Set up 6 air movers and 2 dehumidifiers. Will check moisture readings tomorrow morning.", at: now - 2.days + 5.hours },
      { user: pm1,     body: "Residents in 304 and 306 are asking about timeline. When can they return?", at: now - 1.day },
      { user: reviewer, body: "Based on initial readings, we're looking at 3-4 days of drying minimum. I'll have a better estimate after tomorrow's moisture check.", at: now - 1.day + 2.hours },
    ].each { |msg| Message.create!(incident: i1, user: msg[:user], body: msg[:body], created_at: msg[:at]) }

    day1 = (now - 2.days).to_date
    day2 = (now - 1.day).to_date

    LaborEntry.create!(incident: i1, user: tech1, created_by_user: tech1,
      role_label: "Technician", log_date: day1, hours: 7.0,
      started_at: day1.beginning_of_day + 8.hours, ended_at: day1.beginning_of_day + 15.hours,
      notes: "Water extraction, equipment setup across units 304-306")
    LaborEntry.create!(incident: i1, user: tech2, created_by_user: tech2,
      role_label: "Technician", log_date: day1, hours: 5.5,
      started_at: day1.beginning_of_day + 9.hours, ended_at: day1.beginning_of_day + 14.hours + 30.minutes,
      notes: "Assisted with extraction, set up containment barriers")
    LaborEntry.create!(incident: i1, user: tech1, created_by_user: tech1,
      role_label: "Technician", log_date: day2, hours: 3.0,
      started_at: day2.beginning_of_day + 7.hours, ended_at: day2.beginning_of_day + 10.hours,
      notes: "Morning moisture readings, adjusted equipment positioning")

    6.times do |i|
      loc = ["Unit 304, living room", "Unit 304, bedroom", "Unit 305, kitchen", "Unit 305, hallway", "Unit 306, bedroom", "Unit 306, living room"][i]
      EquipmentEntry.create!(incident: i1, equipment_type: eq_air_mover,
        equipment_identifier: "AM-#{100 + i}", placed_at: now - 2.days + 4.hours,
        location_notes: loc, logged_by_user: tech1)
    end
    2.times do |i|
      EquipmentEntry.create!(incident: i1, equipment_type: eq_dehumidifier,
        equipment_identifier: "DH-#{200 + i}", placed_at: now - 2.days + 4.hours,
        location_notes: i.zero? ? "Unit 305, living room" : "3rd floor hallway",
        logged_by_user: tech1)
    end

    # ========================================================================
    # Incident 2: Proposal submitted — mold at Cedar Ridge
    # ========================================================================
    i2 = Incident.create!(
      property: cedar_ridge,
      created_by_user: pm2,
      status: "proposal_submitted",
      project_type: "mitigation_rfq",
      damage_type: "mold",
      description: "Mold discovered during routine HVAC inspection in units 112 and 114. Visible growth on interior walls near air handler closets. Musty odor reported by residents for several weeks prior to discovery.",
      cause: "HVAC condensation leak behind drywall",
      requested_next_steps: "Please provide scope and estimate for mold remediation in both units.",
      units_affected: 2,
      affected_room_numbers: "112, 114",
      last_activity_at: now - 3.days,
      created_at: now - 5.days
    )

    [reviewer, office].each do |u|
      IncidentAssignment.create!(incident: i2, user: u, assigned_by_user: reviewer)
    end
    IncidentAssignment.create!(incident: i2, user: pm2, assigned_by_user: pm2)

    ActivityEvent.create!(incident: i2, event_type: "incident_created", performed_by_user: pm2,
      metadata: { project_type: "mitigation_rfq", damage_type: "mold" }, created_at: now - 5.days)
    ActivityEvent.create!(incident: i2, event_type: "status_changed", performed_by_user: reviewer,
      metadata: { old_status: "new", new_status: "proposal_submitted" }, created_at: now - 3.days)

    [
      { user: pm2,     body: "Found visible mold during HVAC inspection in two units. Residents have been complaining about musty smell. Need an estimate ASAP.", at: now - 5.days },
      { user: reviewer, body: "I'll send Jordan out tomorrow to assess the scope. We'll have a proposal to you within 48 hours.", at: now - 5.days + 3.hours },
      { user: office,  body: "Completed the site assessment. Both units need full mold remediation — affected drywall removal, HEPA treatment, and reconstruction. Proposal sent to your email.", at: now - 3.days },
    ].each { |msg| Message.create!(incident: i2, user: msg[:user], body: msg[:body], created_at: msg[:at]) }

    # ========================================================================
    # Incident 3: Completed — fire/smoke at Magnolia Gardens
    # ========================================================================
    i3 = Incident.create!(
      property: magnolia,
      created_by_user: pm1,
      status: "completed",
      project_type: "emergency_response",
      damage_type: "fire",
      description: "Kitchen fire in unit 201. Fire department responded and extinguished. Smoke damage throughout the unit and into adjacent hallway. Ceiling and cabinets charred in kitchen area. Resident is temporarily relocated.",
      cause: "Unattended cooking grease fire",
      requested_next_steps: "Board up, smoke damage assessment, and begin cleanup.",
      units_affected: 1,
      affected_room_numbers: "201",
      last_activity_at: now - 8.days,
      created_at: now - 14.days
    )

    [reviewer, tech1].each do |u|
      IncidentAssignment.create!(incident: i3, user: u, assigned_by_user: reviewer)
    end
    IncidentAssignment.create!(incident: i3, user: pm1, assigned_by_user: pm1)

    ActivityEvent.create!(incident: i3, event_type: "incident_created", performed_by_user: pm1,
      metadata: { project_type: "emergency_response", damage_type: "fire" }, created_at: now - 14.days)
    ActivityEvent.create!(incident: i3, event_type: "status_changed", performed_by_user: reviewer,
      metadata: { old_status: "new", new_status: "active" }, created_at: now - 14.days + 1.hour)
    ActivityEvent.create!(incident: i3, event_type: "status_changed", performed_by_user: reviewer,
      metadata: { old_status: "active", new_status: "completed" }, created_at: now - 8.days)

    [
      { user: pm1,     body: "Fire department just left unit 201. Kitchen is destroyed — grease fire that spread to the cabinets and ceiling. Heavy smoke throughout.", at: now - 14.days },
      { user: reviewer, body: "Marcus is heading over now to board up and do the initial assessment. We'll have a full scope by end of day tomorrow.", at: now - 14.days + 1.hour },
      { user: tech1,   body: "Unit boarded up and secured. Smoke damage is extensive — every room has soot on the walls and ceiling. Kitchen will need full demo. Starting HEPA filtration.", at: now - 14.days + 4.hours },
      { user: tech1,   body: "Smoke cleanup complete. Kitchen demo done, air scrubbers ran for 3 days. Air quality tests came back clean. Ready for reconstruction.", at: now - 8.days },
    ].each { |msg| Message.create!(incident: i3, user: msg[:user], body: msg[:body], created_at: msg[:at]) }

    LaborEntry.create!(incident: i3, user: tech1, created_by_user: tech1,
      role_label: "Technician", log_date: (now - 14.days).to_date, hours: 4.0,
      started_at: (now - 14.days).beginning_of_day + 10.hours, ended_at: (now - 14.days).beginning_of_day + 14.hours,
      notes: "Board up, initial assessment, HEPA setup")
    LaborEntry.create!(incident: i3, user: tech1, created_by_user: tech1,
      role_label: "Technician", log_date: (now - 13.days).to_date, hours: 8.0,
      started_at: (now - 13.days).beginning_of_day + 7.hours, ended_at: (now - 13.days).beginning_of_day + 15.hours,
      notes: "Kitchen demolition, soot removal, air scrubber monitoring")

    EquipmentEntry.create!(incident: i3, equipment_type: eq_air_scrubber,
      equipment_identifier: "AS-300", placed_at: now - 14.days + 4.hours,
      removed_at: now - 10.days, location_notes: "Unit 201, living room",
      logged_by_user: tech1)

    # ========================================================================
    # Incident 4: New — odor complaint at Lakewood Terrace
    # ========================================================================
    i4 = Incident.create!(
      property: lakewood,
      created_by_user: pm1,
      status: "new",
      project_type: "mitigation_rfq",
      damage_type: "odor",
      description: "Persistent sewage odor in units 108 and 110 on the first floor. Residents have reported the smell for about two weeks. Maintenance checked plumbing and found no visible leaks. Need professional assessment.",
      cause: nil,
      requested_next_steps: "Assess source of odor and provide remediation plan.",
      units_affected: 2,
      affected_room_numbers: "108, 110",
      last_activity_at: now - 6.hours,
      created_at: now - 6.hours
    )

    IncidentAssignment.create!(incident: i4, user: pm1, assigned_by_user: pm1)

    ActivityEvent.create!(incident: i4, event_type: "incident_created", performed_by_user: pm1,
      metadata: { project_type: "mitigation_rfq", damage_type: "odor" }, created_at: now - 6.hours)

    # ========================================================================
    # Incident 5: Active — storm damage at Cedar Ridge
    # ========================================================================
    i5 = Incident.create!(
      property: cedar_ridge,
      created_by_user: pm2,
      status: "active",
      project_type: "emergency_response",
      damage_type: "flood",
      description: "Severe thunderstorm caused roof leak in building C. Water came through the ceiling in units 301, 302, and 303. Significant ceiling damage and wet carpet in all three units. Tarps placed on roof temporarily.",
      cause: "Storm damage to roof membrane on building C",
      requested_next_steps: "Extract standing water, dry out units, assess structural damage to ceiling.",
      units_affected: 3,
      affected_room_numbers: "301, 302, 303",
      last_activity_at: now - 1.day,
      created_at: now - 3.days
    )

    [reviewer, tech2].each do |u|
      IncidentAssignment.create!(incident: i5, user: u, assigned_by_user: reviewer)
    end
    IncidentAssignment.create!(incident: i5, user: pm2, assigned_by_user: pm2)

    ActivityEvent.create!(incident: i5, event_type: "incident_created", performed_by_user: pm2,
      metadata: { project_type: "emergency_response", damage_type: "flood" }, created_at: now - 3.days)
    ActivityEvent.create!(incident: i5, event_type: "status_changed", performed_by_user: reviewer,
      metadata: { old_status: "new", new_status: "active" }, created_at: now - 3.days + 2.hours)

    [
      { user: pm2,    body: "Last night's storm caused major roof leak in building C. Three units on the third floor have water coming through the ceiling. Maintenance put tarps up but it's still dripping.", at: now - 3.days },
      { user: reviewer, body: "Sarah is heading out now. We'll get extraction started and assess the ceiling damage once things dry out.", at: now - 3.days + 1.hour },
      { user: tech2,  body: "On site. Extracted standing water from all three units. Ceiling drywall is sagging in 301 and 302 — will need replacement. Set up drying equipment.", at: now - 3.days + 5.hours },
      { user: tech2,  body: "Day 2 readings: moisture levels dropping but 301 ceiling is still saturated. Removed damaged drywall section to help with airflow. Added another air mover.", at: now - 1.day },
    ].each { |msg| Message.create!(incident: i5, user: msg[:user], body: msg[:body], created_at: msg[:at]) }

    LaborEntry.create!(incident: i5, user: tech2, created_by_user: tech2,
      role_label: "Technician", log_date: (now - 3.days).to_date, hours: 6.0,
      started_at: (now - 3.days).beginning_of_day + 9.hours, ended_at: (now - 3.days).beginning_of_day + 15.hours,
      notes: "Water extraction, ceiling assessment, drying equipment setup")

    4.times do |i|
      loc = ["Unit 301, living room", "Unit 301, bedroom", "Unit 302, living room", "Unit 303, living room"][i]
      EquipmentEntry.create!(incident: i5, equipment_type: eq_air_mover,
        equipment_identifier: "AM-#{110 + i}", placed_at: now - 3.days + 5.hours,
        location_notes: loc, logged_by_user: tech2)
    end
    EquipmentEntry.create!(incident: i5, equipment_type: eq_dehumidifier,
      equipment_identifier: "DH-210", placed_at: now - 3.days + 5.hours,
      location_notes: "Unit 302, hallway", logged_by_user: tech2)

    puts "  Incidents: 5"

    # ========================================================================
    # Done
    # ========================================================================
    puts ""
    puts "=== Apple Review Demo Account ==="
    puts "Email:    #{DEMO_MIT_EMAIL}"
    puts "Password: #{DEMO_PASSWORD}"
    puts "Role:     Manager at Summit Restoration"
    puts ""
    puts "The reviewer will see:"
    puts "  - 5 incidents across 3 properties (various statuses)"
    puts "  - Messages, labor entries, equipment tracking"
    puts "  - 6 team members across 2 organizations"
    puts ""
    puts "To tear down: bin/rails demo:teardown"
    puts "================================="
  end

  desc "Remove all demo data"
  task teardown: :environment do
    teardown_existing!
    puts "Demo data removed."
  end

  def self.teardown_existing!
    # Remove any leftover demo user from older versions of this task
    User.where(email_address: DEMO_MIT_EMAIL).destroy_all

    demo_orgs = Organization.where("name LIKE ?", "#{DEMO_ORG_PREFIX}%")
    return if demo_orgs.empty?

    puts "  Removing existing demo data..."
    # Incidents belong to properties which belong to orgs — destroy in order
    demo_org_ids = demo_orgs.pluck(:id)
    demo_properties = Property.where(mitigation_org_id: demo_org_ids).or(Property.where(property_management_org_id: demo_org_ids))
    Incident.where(property_id: demo_properties.pluck(:id)).destroy_all
    demo_properties.destroy_all
    User.where(organization_id: demo_org_ids).destroy_all
    EquipmentType.where(organization_id: demo_org_ids).destroy_all
    demo_orgs.destroy_all
  end

  def self.create_user!(org, email, first_name, last_name, user_type, phone)
    User.create!(
      organization: org,
      email_address: email,
      first_name: first_name,
      last_name: last_name,
      user_type: user_type,
      phone: phone,
      password: DEMO_PASSWORD,
      timezone: "Central Time (US & Canada)",
      active: true
    )
  end
end
