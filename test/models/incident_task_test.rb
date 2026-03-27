require "test_helper"

class IncidentTaskTest < ActiveSupport::TestCase
  setup do
    @org = Organization.create!(name: "Task Test Org", organization_type: "mitigation")
    @pm_org = Organization.create!(name: "PM Org", organization_type: "property_management")
    @property = Property.create!(name: "Task Prop", mitigation_org: @org, property_management_org: @pm_org)
    @user = @org.users.create!(
      first_name: "Test", last_name: "User", email_address: "task-test@example.com",
      user_type: "manager", password: "password123"
    )
    @incident = Incident.create!(
      property: @property, created_by_user: @user,
      status: "active", project_type: "emergency_response",
      damage_type: "flood", description: "Test"
    )
    @unit = @incident.incident_units.create!(unit_number: "320", created_by_user: @user)
  end

  test "valid task" do
    task = @unit.incident_tasks.new(
      activity: "Remediation", start_date: Date.current, end_date: Date.current + 5,
      created_by_user: @user
    )
    assert task.valid?
  end

  test "requires activity" do
    task = @unit.incident_tasks.new(
      activity: "", start_date: Date.current, end_date: Date.current + 1,
      created_by_user: @user
    )
    assert_not task.valid?
    assert_includes task.errors[:activity], "can't be blank"
  end

  test "requires start_date" do
    task = @unit.incident_tasks.new(
      activity: "Rebuild", start_date: nil, end_date: Date.current,
      created_by_user: @user
    )
    assert_not task.valid?
    assert_includes task.errors[:start_date], "can't be blank"
  end

  test "requires end_date" do
    task = @unit.incident_tasks.new(
      activity: "Rebuild", start_date: Date.current, end_date: nil,
      created_by_user: @user
    )
    assert_not task.valid?
    assert_includes task.errors[:end_date], "can't be blank"
  end

  test "end_date cannot be before start_date" do
    task = @unit.incident_tasks.new(
      activity: "Rebuild", start_date: Date.current, end_date: Date.current - 1,
      created_by_user: @user
    )
    assert_not task.valid?
    assert_includes task.errors[:end_date], "cannot be before start date"
  end

  test "end_date can equal start_date" do
    task = @unit.incident_tasks.new(
      activity: "Inspection", start_date: Date.current, end_date: Date.current,
      created_by_user: @user
    )
    assert task.valid?
  end

  test "delegates incident to incident_unit" do
    task = @unit.incident_tasks.create!(
      activity: "Paint", start_date: Date.current, end_date: Date.current + 2,
      created_by_user: @user
    )
    assert_equal @incident, task.incident
  end
end
