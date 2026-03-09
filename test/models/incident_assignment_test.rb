require "test_helper"

class IncidentAssignmentTest < ActiveSupport::TestCase
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @property = Property.create!(name: "Sunset Apts", mitigation_org: @genixo, property_management_org: @greystar)

    @user = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123",
      notification_preferences: { "status_change" => true, "new_message" => false })

    @incident = Incident.create!(
      property: @property, created_by_user: @user, status: "active",
      project_type: "emergency_response", damage_type: "flood", description: "Test", emergency: true
    )
    @assignment = IncidentAssignment.create!(incident: @incident, user: @user, assigned_by_user: @user)
  end

  test "falls back to global preference when no override" do
    assert_equal true, @assignment.effective_notification_preference("status_change")
    assert_equal false, @assignment.effective_notification_preference("new_message")
  end

  test "override takes precedence over global" do
    @assignment.update!(notification_overrides: { "status_change" => false, "new_message" => true })
    assert_equal false, @assignment.effective_notification_preference("status_change")
    assert_equal true, @assignment.effective_notification_preference("new_message")
  end

  test "clearing overrides reverts to global" do
    @assignment.update!(notification_overrides: { "status_change" => false })
    assert_equal false, @assignment.effective_notification_preference("status_change")

    @assignment.update!(notification_overrides: {})
    assert_equal true, @assignment.effective_notification_preference("status_change")
  end

  test "accepts string or symbol key" do
    @assignment.update!(notification_overrides: { "new_message" => true })
    assert_equal true, @assignment.effective_notification_preference(:new_message)
  end
end
