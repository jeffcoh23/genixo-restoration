require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @unrelated_pm = Organization.create!(name: "Unrelated PM", organization_type: "property_management")

    # Genixo services Greystar via a property
    Property.create!(name: "Test Prop", property_management_org: @greystar, mitigation_org: @genixo)

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @office = User.create!(organization: @genixo, user_type: "office_sales",
      email_address: "office@genixo.com", first_name: "Test", last_name: "Office", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "Test", last_name: "Tech", password: "password123")
    @pm_user = User.create!(organization: @greystar, user_type: "property_manager",
      email_address: "pm@greystar.com", first_name: "Test", last_name: "PM", password: "password123")
  end

  # --- Access control for create/resend ---

  test "manager can create invitation to own org" do
    login_as @manager
    assert_difference "Invitation.count", 1 do
      post invitations_path, params: {
        email: "new@genixo.com", user_type: "technician"
      }
    end
    assert_redirected_to users_path
    inv = Invitation.last
    assert_equal @genixo.id, inv.organization_id
    assert_equal "new@genixo.com", inv.email
    assert_equal "technician", inv.user_type
  end

  test "office_sales can create invitation" do
    login_as @office
    assert_difference "Invitation.count", 1 do
      post invitations_path, params: {
        email: "sales@genixo.com", user_type: "office_sales"
      }
    end
    assert_redirected_to users_path
  end

  test "technician cannot create invitation" do
    login_as @tech
    post invitations_path, params: {
      email: "nobody@genixo.com", user_type: "technician"
    }
    assert_response :not_found
  end

  test "PM user cannot create invitation" do
    login_as @pm_user
    post invitations_path, params: {
      email: "nobody@pm.com", user_type: "property_manager"
    }
    assert_response :not_found
  end

  # --- Cross-org invitations ---

  test "manager can invite to serviced PM org" do
    login_as @manager
    assert_difference "Invitation.count", 1 do
      post invitations_path, params: {
        email: "newpm@greystar.com", user_type: "property_manager",
        organization_id: @greystar.id
      }
    end
    inv = Invitation.last
    assert_equal @greystar.id, inv.organization_id
  end

  test "manager cannot invite to unrelated PM org" do
    login_as @manager
    assert_no_difference "Invitation.count" do
      post invitations_path, params: {
        email: "hack@unrelated.com", user_type: "property_manager",
        organization_id: @unrelated_pm.id
      }
    end
    assert_response :not_found
  end

  # --- Invitation with optional fields ---

  test "invitation saves optional first_name, last_name, phone" do
    login_as @manager
    post invitations_path, params: {
      email: "full@genixo.com", user_type: "technician",
      first_name: "John", last_name: "Doe", phone: "555-1234"
    }
    inv = Invitation.last
    assert_equal "John", inv.first_name
    assert_equal "Doe", inv.last_name
    assert_equal "555-1234", inv.phone
  end

  # --- Resend ---

  test "manager can resend pending invitation" do
    login_as @manager
    inv = @genixo.invitations.create!(
      invited_by_user: @manager, email: "pending@genixo.com",
      user_type: "technician", expires_at: 7.days.from_now
    )
    old_token = inv.token

    patch resend_invitation_path(inv)
    assert_redirected_to users_path
    inv.reload
    assert_not_equal old_token, inv.token
    assert inv.expires_at > Time.current
  end

  # --- Show (unauthenticated) ---

  test "show renders acceptance form for valid token" do
    inv = @genixo.invitations.create!(
      invited_by_user: @manager, email: "accept@genixo.com",
      user_type: "technician", expires_at: 7.days.from_now
    )
    get invitation_path(inv.token)
    assert_response :success
  end

  test "show redirects for already-accepted invitation" do
    inv = @genixo.invitations.create!(
      invited_by_user: @manager, email: "done@genixo.com",
      user_type: "technician", expires_at: 7.days.from_now,
      accepted_at: 1.day.ago
    )
    get invitation_path(inv.token)
    assert_redirected_to login_path
  end

  test "show renders expired page for expired invitation" do
    inv = @genixo.invitations.create!(
      invited_by_user: @manager, email: "old@genixo.com",
      user_type: "technician", expires_at: 1.day.ago
    )
    get invitation_path(inv.token)
    assert_response :success
  end

  # --- Accept (unauthenticated) ---

  test "accept creates user and logs in" do
    inv = @genixo.invitations.create!(
      invited_by_user: @manager, email: "newuser@genixo.com",
      user_type: "technician", expires_at: 7.days.from_now,
      first_name: "Jane"
    )

    assert_difference "User.count", 1 do
      post accept_invitation_path(inv.token), params: {
        first_name: "Jane", last_name: "Smith",
        phone: "555-0000",
        password: "password123", password_confirmation: "password123"
      }
    end
    assert_redirected_to dashboard_path

    user = User.find_by(email_address: "newuser@genixo.com")
    assert_equal "Jane", user.first_name
    assert_equal "Smith", user.last_name
    assert_equal "technician", user.user_type
    assert_equal @genixo.id, user.organization_id

    inv.reload
    assert inv.accepted?
  end

  test "accept rejects expired invitation" do
    inv = @genixo.invitations.create!(
      invited_by_user: @manager, email: "expired@genixo.com",
      user_type: "technician", expires_at: 1.day.ago
    )

    assert_no_difference "User.count" do
      post accept_invitation_path(inv.token), params: {
        first_name: "No", last_name: "Way",
        password: "password123", password_confirmation: "password123"
      }
    end
    assert_redirected_to login_path
  end

  test "accept rejects already-accepted invitation" do
    inv = @genixo.invitations.create!(
      invited_by_user: @manager, email: "already@genixo.com",
      user_type: "technician", expires_at: 7.days.from_now,
      accepted_at: 1.day.ago
    )

    assert_no_difference "User.count" do
      post accept_invitation_path(inv.token), params: {
        first_name: "No", last_name: "Way",
        password: "password123", password_confirmation: "password123"
      }
    end
    assert_redirected_to login_path
  end

  test "accept shows errors for invalid user data" do
    inv = @genixo.invitations.create!(
      invited_by_user: @manager, email: "bad@genixo.com",
      user_type: "technician", expires_at: 7.days.from_now
    )

    assert_no_difference "User.count" do
      post accept_invitation_path(inv.token), params: {
        first_name: "", last_name: "",
        password: "short", password_confirmation: "mismatch"
      }
    end
    assert_redirected_to invitation_path(inv.token)
  end

  private

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end
end
