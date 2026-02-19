# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_02_18_205805) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activity_entries", force: :cascade do |t|
    t.bigint "incident_id", null: false
    t.bigint "performed_by_user_id", null: false
    t.string "title", null: false
    t.text "details"
    t.integer "units_affected"
    t.text "units_affected_description"
    t.string "status", default: "active", null: false
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "visitors"
    t.string "usable_rooms_returned"
    t.date "estimated_date_of_return"
    t.index ["incident_id", "occurred_at"], name: "index_activity_entries_on_incident_id_and_occurred_at"
    t.index ["incident_id"], name: "index_activity_entries_on_incident_id"
    t.index ["performed_by_user_id"], name: "index_activity_entries_on_performed_by_user_id"
    t.index ["status"], name: "index_activity_entries_on_status"
  end

  create_table "activity_equipment_actions", force: :cascade do |t|
    t.bigint "activity_entry_id", null: false
    t.bigint "equipment_type_id"
    t.bigint "equipment_entry_id"
    t.string "equipment_type_other"
    t.string "action_type", null: false
    t.integer "quantity"
    t.text "note"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action_type"], name: "index_activity_equipment_actions_on_action_type"
    t.index ["activity_entry_id", "position"], name: "index_act_eq_actions_on_entry_and_position"
    t.index ["activity_entry_id"], name: "index_activity_equipment_actions_on_activity_entry_id"
    t.index ["equipment_entry_id"], name: "index_activity_equipment_actions_on_equipment_entry_id"
    t.index ["equipment_type_id"], name: "index_activity_equipment_actions_on_equipment_type_id"
  end

  create_table "activity_events", force: :cascade do |t|
    t.bigint "incident_id", null: false
    t.string "event_type", null: false
    t.bigint "performed_by_user_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.index ["event_type"], name: "index_activity_events_on_event_type"
    t.index ["incident_id", "created_at"], name: "index_activity_events_on_incident_id_and_created_at"
    t.index ["incident_id"], name: "index_activity_events_on_incident_id"
    t.index ["performed_by_user_id"], name: "index_activity_events_on_performed_by_user_id"
  end

  create_table "attachments", force: :cascade do |t|
    t.string "attachable_type", null: false
    t.bigint "attachable_id", null: false
    t.bigint "uploaded_by_user_id", null: false
    t.string "category", null: false
    t.string "description"
    t.date "log_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attachable_type", "attachable_id", "category"], name: "idx_on_attachable_type_attachable_id_category_16fe0cfdc5"
    t.index ["attachable_type", "attachable_id", "log_date"], name: "idx_on_attachable_type_attachable_id_log_date_9509925004"
    t.index ["attachable_type", "attachable_id"], name: "index_attachments_on_attachable"
    t.index ["uploaded_by_user_id"], name: "index_attachments_on_uploaded_by_user_id"
  end

  create_table "equipment_entries", force: :cascade do |t|
    t.bigint "incident_id", null: false
    t.bigint "equipment_type_id"
    t.string "equipment_type_other"
    t.string "equipment_identifier"
    t.datetime "placed_at", null: false
    t.datetime "removed_at"
    t.text "location_notes"
    t.bigint "logged_by_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "equipment_model"
    t.index ["equipment_identifier"], name: "index_equipment_entries_on_equipment_identifier"
    t.index ["equipment_type_id"], name: "index_equipment_entries_on_equipment_type_id"
    t.index ["incident_id"], name: "index_equipment_entries_on_incident_id"
    t.index ["logged_by_user_id"], name: "index_equipment_entries_on_logged_by_user_id"
  end

  create_table "equipment_types", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "name"], name: "index_equipment_types_on_organization_id_and_name", unique: true
    t.index ["organization_id"], name: "index_equipment_types_on_organization_id"
  end

  create_table "escalation_contacts", force: :cascade do |t|
    t.bigint "on_call_configuration_id", null: false
    t.bigint "user_id", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["on_call_configuration_id", "position"], name: "index_escalation_contacts_on_config_id_and_position", unique: true
    t.index ["on_call_configuration_id"], name: "index_escalation_contacts_on_on_call_configuration_id"
    t.index ["user_id"], name: "index_escalation_contacts_on_user_id"
  end

  create_table "escalation_events", force: :cascade do |t|
    t.bigint "incident_id", null: false
    t.bigint "user_id", null: false
    t.string "contact_method", null: false
    t.string "provider"
    t.string "status", null: false
    t.datetime "attempted_at", null: false
    t.datetime "resolved_at"
    t.bigint "resolved_by_user_id"
    t.string "resolution_reason"
    t.jsonb "provider_response", default: {}
    t.datetime "created_at", null: false
    t.index ["incident_id"], name: "index_escalation_events_on_incident_id"
    t.index ["resolved_by_user_id"], name: "index_escalation_events_on_resolved_by_user_id"
    t.index ["status"], name: "index_escalation_events_on_status"
    t.index ["user_id"], name: "index_escalation_events_on_user_id"
  end

  create_table "incident_assignments", force: :cascade do |t|
    t.bigint "incident_id", null: false
    t.bigint "user_id", null: false
    t.bigint "assigned_by_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_by_user_id"], name: "index_incident_assignments_on_assigned_by_user_id"
    t.index ["incident_id", "user_id"], name: "index_incident_assignments_on_incident_id_and_user_id", unique: true
    t.index ["incident_id"], name: "index_incident_assignments_on_incident_id"
    t.index ["user_id"], name: "index_incident_assignments_on_user_id"
  end

  create_table "incident_contacts", force: :cascade do |t|
    t.bigint "incident_id", null: false
    t.string "name", null: false
    t.string "title"
    t.string "email"
    t.string "phone"
    t.bigint "created_by_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "onsite", default: false, null: false
    t.index ["created_by_user_id"], name: "index_incident_contacts_on_created_by_user_id"
    t.index ["incident_id"], name: "index_incident_contacts_on_incident_id"
  end

  create_table "incident_read_states", force: :cascade do |t|
    t.bigint "incident_id", null: false
    t.bigint "user_id", null: false
    t.datetime "last_message_read_at"
    t.datetime "last_activity_read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["incident_id", "user_id"], name: "index_incident_read_states_on_incident_id_and_user_id", unique: true
    t.index ["incident_id"], name: "index_incident_read_states_on_incident_id"
    t.index ["user_id"], name: "index_incident_read_states_on_user_id"
  end

  create_table "incidents", force: :cascade do |t|
    t.bigint "property_id", null: false
    t.bigint "created_by_user_id", null: false
    t.string "status", default: "new", null: false
    t.string "project_type", null: false
    t.boolean "emergency", default: false, null: false
    t.string "damage_type", null: false
    t.text "description", null: false
    t.text "cause"
    t.text "requested_next_steps"
    t.integer "units_affected"
    t.text "affected_room_numbers"
    t.datetime "last_activity_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "job_id"
    t.text "visitors"
    t.text "usable_rooms_returned"
    t.date "estimated_date_of_return"
    t.decimal "do_not_exceed_limit"
    t.text "location_of_damage"
    t.index ["created_by_user_id"], name: "index_incidents_on_created_by_user_id"
    t.index ["emergency"], name: "index_incidents_on_emergency", where: "(emergency = true)"
    t.index ["last_activity_at"], name: "index_incidents_on_last_activity_at"
    t.index ["project_type"], name: "index_incidents_on_project_type"
    t.index ["property_id", "status"], name: "index_incidents_on_property_id_and_status"
    t.index ["property_id"], name: "index_incidents_on_property_id"
    t.index ["status", "last_activity_at"], name: "index_incidents_on_status_and_last_activity_at"
    t.index ["status"], name: "index_incidents_on_status"
  end

  create_table "invitations", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "invited_by_user_id", null: false
    t.string "email", null: false
    t.string "user_type", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.string "token", null: false
    t.datetime "accepted_at"
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_invitations_on_email"
    t.index ["invited_by_user_id"], name: "index_invitations_on_invited_by_user_id"
    t.index ["organization_id"], name: "index_invitations_on_organization_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "labor_entries", force: :cascade do |t|
    t.bigint "incident_id", null: false
    t.bigint "user_id"
    t.string "role_label", null: false
    t.date "log_date", null: false
    t.datetime "started_at"
    t.datetime "ended_at"
    t.decimal "hours", precision: 5, scale: 2, null: false
    t.text "notes"
    t.bigint "created_by_user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_user_id"], name: "index_labor_entries_on_created_by_user_id"
    t.index ["incident_id", "log_date"], name: "index_labor_entries_on_incident_id_and_log_date"
    t.index ["incident_id"], name: "index_labor_entries_on_incident_id"
    t.index ["user_id"], name: "index_labor_entries_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "incident_id", null: false
    t.bigint "user_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["incident_id", "created_at"], name: "index_messages_on_incident_id_and_created_at"
    t.index ["incident_id"], name: "index_messages_on_incident_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "on_call_configurations", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "primary_user_id", null: false
    t.integer "escalation_timeout_minutes", default: 10, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_on_call_configurations_on_organization_id", unique: true
    t.index ["primary_user_id"], name: "index_on_call_configurations_on_primary_user_id"
  end

  create_table "operational_notes", force: :cascade do |t|
    t.bigint "incident_id", null: false
    t.bigint "created_by_user_id", null: false
    t.text "note_text", null: false
    t.date "log_date", null: false
    t.datetime "created_at", null: false
    t.index ["created_by_user_id"], name: "index_operational_notes_on_created_by_user_id"
    t.index ["incident_id", "created_at"], name: "index_operational_notes_on_incident_id_and_created_at"
    t.index ["incident_id", "log_date"], name: "index_operational_notes_on_incident_id_and_log_date"
    t.index ["incident_id"], name: "index_operational_notes_on_incident_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "organization_type", null: false
    t.string "phone"
    t.string "email"
    t.string "street_address"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_type"], name: "index_organizations_on_organization_type"
  end

  create_table "properties", force: :cascade do |t|
    t.bigint "property_management_org_id", null: false
    t.bigint "mitigation_org_id", null: false
    t.string "name", null: false
    t.string "street_address"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.integer "unit_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["mitigation_org_id"], name: "index_properties_on_mitigation_org_id"
    t.index ["property_management_org_id"], name: "index_properties_on_property_management_org_id"
  end

  create_table "property_assignments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "property_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_property_assignments_on_property_id"
    t.index ["user_id", "property_id"], name: "index_property_assignments_on_user_id_and_property_id", unique: true
    t.index ["user_id"], name: "index_property_assignments_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.binary "payload", null: false
    t.datetime "created_at", null: false
    t.bigint "channel_hash", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "email_address", null: false
    t.string "password_digest"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "phone"
    t.string "timezone", default: "America/Chicago", null: false
    t.string "user_type", null: false
    t.jsonb "notification_preferences", default: {}, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address"
    t.index ["organization_id", "email_address"], name: "index_users_on_organization_id_and_email_address", unique: true
    t.index ["organization_id", "user_type"], name: "index_users_on_organization_id_and_user_type"
    t.index ["organization_id"], name: "index_users_on_organization_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activity_entries", "incidents"
  add_foreign_key "activity_entries", "users", column: "performed_by_user_id"
  add_foreign_key "activity_equipment_actions", "activity_entries"
  add_foreign_key "activity_equipment_actions", "equipment_entries"
  add_foreign_key "activity_equipment_actions", "equipment_types"
  add_foreign_key "activity_events", "incidents"
  add_foreign_key "activity_events", "users", column: "performed_by_user_id"
  add_foreign_key "attachments", "users", column: "uploaded_by_user_id"
  add_foreign_key "equipment_entries", "equipment_types"
  add_foreign_key "equipment_entries", "incidents"
  add_foreign_key "equipment_entries", "users", column: "logged_by_user_id"
  add_foreign_key "equipment_types", "organizations"
  add_foreign_key "escalation_contacts", "on_call_configurations"
  add_foreign_key "escalation_contacts", "users"
  add_foreign_key "escalation_events", "incidents"
  add_foreign_key "escalation_events", "users"
  add_foreign_key "escalation_events", "users", column: "resolved_by_user_id"
  add_foreign_key "incident_assignments", "incidents"
  add_foreign_key "incident_assignments", "users"
  add_foreign_key "incident_assignments", "users", column: "assigned_by_user_id"
  add_foreign_key "incident_contacts", "incidents"
  add_foreign_key "incident_contacts", "users", column: "created_by_user_id"
  add_foreign_key "incident_read_states", "incidents"
  add_foreign_key "incident_read_states", "users"
  add_foreign_key "incidents", "properties"
  add_foreign_key "incidents", "users", column: "created_by_user_id"
  add_foreign_key "invitations", "organizations"
  add_foreign_key "invitations", "users", column: "invited_by_user_id"
  add_foreign_key "labor_entries", "incidents"
  add_foreign_key "labor_entries", "users"
  add_foreign_key "labor_entries", "users", column: "created_by_user_id"
  add_foreign_key "messages", "incidents"
  add_foreign_key "messages", "users"
  add_foreign_key "on_call_configurations", "organizations"
  add_foreign_key "on_call_configurations", "users", column: "primary_user_id"
  add_foreign_key "operational_notes", "incidents"
  add_foreign_key "operational_notes", "users", column: "created_by_user_id"
  add_foreign_key "properties", "organizations", column: "mitigation_org_id"
  add_foreign_key "properties", "organizations", column: "property_management_org_id"
  add_foreign_key "property_assignments", "properties"
  add_foreign_key "property_assignments", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "users", "organizations"
end
