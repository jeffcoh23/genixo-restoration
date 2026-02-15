require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
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
    @office_sales = User.create!(organization: @genixo, user_type: "office_sales",
      email_address: "sales@genixo.com", first_name: "Test", last_name: "Sales", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "Test", last_name: "Tech", password: "password123")
    @unassigned_tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech2@genixo.com", first_name: "Other", last_name: "Tech", password: "password123")
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
  end

  test "manager can send a message" do
    login_as @manager
    assert_difference "Message.count", 1 do
      post incident_messages_path(@incident), params: { message: { body: "Starting work today." } }
    end
    assert_redirected_to incident_path(@incident)
    assert_equal "Starting work today.", Message.last.body
    assert_equal @manager.id, Message.last.user_id
  end

  test "office_sales can send a message" do
    login_as @office_sales
    assert_difference "Message.count", 1 do
      post incident_messages_path(@incident), params: { message: { body: "Quote attached." } }
    end
    assert_redirected_to incident_path(@incident)
  end

  test "assigned tech can send a message" do
    login_as @tech
    assert_difference "Message.count", 1 do
      post incident_messages_path(@incident), params: { message: { body: "On site now." } }
    end
    assert_redirected_to incident_path(@incident)
  end

  test "pm user can send a message" do
    login_as @pm_user
    assert_difference "Message.count", 1 do
      post incident_messages_path(@incident), params: { message: { body: "Any update?" } }
    end
    assert_redirected_to incident_path(@incident)
  end

  test "pm user from different org cannot send a message" do
    login_as @cross_org_pm
    assert_no_difference "Message.count" do
      post incident_messages_path(@incident), params: { message: { body: "Should not work" } }
    end
    assert_response :not_found
  end

  test "unassigned tech cannot send a message" do
    login_as @unassigned_tech
    assert_no_difference "Message.count" do
      post incident_messages_path(@incident), params: { message: { body: "Should not work" } }
    end
    assert_response :not_found
  end

  test "empty body is rejected" do
    login_as @manager
    assert_no_difference "Message.count" do
      post incident_messages_path(@incident), params: { message: { body: "" } }
    end
    assert_redirected_to incident_path(@incident)
  end

  test "sending a message touches last_activity_at but creates no activity event" do
    login_as @manager
    assert_no_difference "ActivityEvent.count" do
      post incident_messages_path(@incident), params: { message: { body: "Update." } }
    end
    @incident.reload
    assert_not_nil @incident.last_activity_at
  end

  test "messages allowed on completed incidents" do
    @incident.update_columns(status: "completed")
    login_as @manager
    assert_difference "Message.count", 1 do
      post incident_messages_path(@incident), params: { message: { body: "Final notes." } }
    end
    assert_redirected_to incident_path(@incident)
  end

  private

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end
end
