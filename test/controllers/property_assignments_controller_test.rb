require "test_helper"

class PropertyAssignmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")

    @property = Property.create!(
      name: "Sunset Apartments", property_management_org: @greystar,
      mitigation_org: @genixo
    )

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "Test", last_name: "Tech", password: "password123")

    @pm_user = User.create!(organization: @greystar, user_type: "property_manager",
      email_address: "pm@greystar.com", first_name: "Jane", last_name: "PM", password: "password123")
    @am_user = User.create!(organization: @greystar, user_type: "area_manager",
      email_address: "am@greystar.com", first_name: "Bob", last_name: "AM", password: "password123")

    # Assign pm_user to property so they can manage assignments
    PropertyAssignment.create!(user: @pm_user, property: @property)
  end

  # --- Create ---

  test "manager can assign a PM user to a property" do
    login_as @manager
    assert_difference "PropertyAssignment.count", 1 do
      post property_assignments_path(@property), params: { user_id: @am_user.id }
    end
    assert_redirected_to property_path(@property)
    assert @property.assigned_users.exists?(id: @am_user.id)
  end

  test "assigned PM user can assign another PM user" do
    login_as @pm_user
    assert_difference "PropertyAssignment.count", 1 do
      post property_assignments_path(@property), params: { user_id: @am_user.id }
    end
    assert_redirected_to property_path(@property)
  end

  test "technician cannot assign users" do
    login_as @tech
    assert_no_difference "PropertyAssignment.count" do
      post property_assignments_path(@property), params: { user_id: @am_user.id }
    end
    assert_response :not_found
  end

  test "duplicate assignment is handled gracefully" do
    login_as @manager
    assert_no_difference "PropertyAssignment.count" do
      post property_assignments_path(@property), params: { user_id: @pm_user.id }
    end
    assert_redirected_to property_path(@property)
    assert_equal "User is already assigned.", flash[:alert]
  end

  # --- Destroy ---

  test "manager can remove an assignment" do
    login_as @manager
    assignment = @property.property_assignments.find_by(user: @pm_user)
    assert_difference "PropertyAssignment.count", -1 do
      delete property_assignment_path(@property, assignment)
    end
    assert_redirected_to property_path(@property)
  end

  test "assigned PM user can remove an assignment" do
    # First add am_user so we can remove them
    assignment = PropertyAssignment.create!(user: @am_user, property: @property)
    login_as @pm_user
    assert_difference "PropertyAssignment.count", -1 do
      delete property_assignment_path(@property, assignment)
    end
    assert_redirected_to property_path(@property)
  end

  test "unassigned PM user cannot remove assignments" do
    login_as @am_user # am_user is not assigned to property
    assignment = @property.property_assignments.find_by(user: @pm_user)
    assert_no_difference "PropertyAssignment.count" do
      delete property_assignment_path(@property, assignment)
    end
    assert_response :not_found
  end

  private

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end
end
