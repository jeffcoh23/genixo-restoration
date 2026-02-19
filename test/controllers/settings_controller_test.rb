require "test_helper"

class SettingsControllerReorderTest < ActionDispatch::IntegrationTest
  setup do
    @org = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @manager = User.create!(organization: @org, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @manager2 = User.create!(organization: @org, user_type: "manager",
      email_address: "mgr2@genixo.com", first_name: "Second", last_name: "Manager", password: "password123")
    @manager3 = User.create!(organization: @org, user_type: "manager",
      email_address: "mgr3@genixo.com", first_name: "Third", last_name: "Manager", password: "password123")

    @config = OnCallConfiguration.create!(organization: @org, primary_user: @manager, escalation_timeout_minutes: 10)
    @c1 = EscalationContact.create!(on_call_configuration: @config, user: @manager, position: 1)
    @c2 = EscalationContact.create!(on_call_configuration: @config, user: @manager2, position: 2)
    @c3 = EscalationContact.create!(on_call_configuration: @config, user: @manager3, position: 3)
  end

  test "reorders escalation contacts" do
    login_as @manager
    patch reorder_escalation_contacts_path, params: { contact_ids: [ @c3.id, @c1.id, @c2.id ] }
    assert_redirected_to on_call_settings_path

    assert_equal 2, @c1.reload.position
    assert_equal 3, @c2.reload.position
    assert_equal 1, @c3.reload.position
  end

  test "rejects invalid contact ids" do
    login_as @manager
    patch reorder_escalation_contacts_path, params: { contact_ids: [ @c1.id, 99999 ] }
    assert_redirected_to on_call_settings_path
    assert_includes flash[:alert], "Invalid"
  end

  test "rejects incomplete contact ids" do
    login_as @manager
    patch reorder_escalation_contacts_path, params: { contact_ids: [ @c1.id, @c2.id ] }
    assert_redirected_to on_call_settings_path
    assert_includes flash[:alert], "Invalid"
  end

  test "requires manager role" do
    tech = User.create!(organization: @org, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "Tech", last_name: "User", password: "password123")
    login_as tech
    patch reorder_escalation_contacts_path, params: { contact_ids: [ @c1.id, @c2.id, @c3.id ] }
    assert_response :not_found
  end

  private

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end
end
