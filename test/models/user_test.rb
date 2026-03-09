require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @mitigation_org = Organization.create!(name: "Test Mitigation", organization_type: "mitigation")
    @pm_org = Organization.create!(name: "Test PM", organization_type: "property_management")
  end

  test "valid mitigation manager" do
    user = build_user(organization: @mitigation_org, user_type: "manager")
    assert user.valid?
    assert user.mitigation_user?
    assert_not user.pm_user?
  end

  test "valid PM property_manager" do
    user = build_user(organization: @pm_org, user_type: "property_manager")
    assert user.valid?
    assert user.pm_user?
    assert_not user.mitigation_user?
  end

  test "rejects PM user type on mitigation org" do
    user = build_user(organization: @mitigation_org, user_type: "property_manager")
    assert_not user.valid?
    assert user.errors[:user_type].any? { |e| e.include?("not valid for a mitigation") }
  end

  test "rejects mitigation user type on PM org" do
    user = build_user(organization: @pm_org, user_type: "technician")
    assert_not user.valid?
    assert user.errors[:user_type].any? { |e| e.include?("not valid for a property management") }
  end

  test "requires email_address" do
    user = build_user(email_address: nil)
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "requires first_name and last_name" do
    user = build_user(first_name: nil, last_name: nil)
    assert_not user.valid?
    assert_includes user.errors[:first_name], "can't be blank"
    assert_includes user.errors[:last_name], "can't be blank"
  end

  test "email uniqueness is global" do
    build_user(organization: @mitigation_org, email_address: "test@example.com").save!
    duplicate = build_user(organization: @mitigation_org, email_address: "test@example.com")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email_address], "has already been taken"
  end

  test "same email rejected across different orgs" do
    build_user(organization: @mitigation_org, email_address: "test@example.com").save!
    other = build_user(organization: @pm_org, email_address: "test@example.com", user_type: "property_manager")
    assert_not other.valid?
    assert_includes other.errors[:email_address], "has already been taken"
  end

  test "normalizes email to lowercase" do
    user = build_user(email_address: "  Test@Example.COM  ")
    user.save!
    assert_equal "test@example.com", user.email_address
  end

  test "full_name combines first and last" do
    user = build_user(first_name: "Jane", last_name: "Doe")
    assert_equal "Jane Doe", user.full_name
  end

  test "initials returns first letters uppercased" do
    user = build_user(first_name: "jane", last_name: "doe")
    assert_equal "JD", user.initials
  end

  test "defaults to active" do
    user = build_user
    assert user.active
  end

  test "defaults timezone to Central Time" do
    user = User.new
    assert_equal "Central Time (US & Canada)", user.timezone
  end

  test "normalizes phone to digits only" do
    user = build_user(phone: "(203) 218-0897")
    user.save!
    assert_equal "2032180897", user.phone
  end

  test "normalizes phone strips leading 1" do
    user = build_user(phone: "1-203-218-0897")
    user.save!
    assert_equal "2032180897", user.phone
  end

  test "normalizes phone preserves nil" do
    user = build_user(phone: nil)
    user.save!
    assert_nil user.phone
  end

  test "normalizes phone preserves blank as nil" do
    user = build_user(phone: "")
    user.save!
    assert_nil user.phone
  end

  test "allows auto_assign for mitigation users" do
    user = build_user(organization: @mitigation_org, user_type: "manager", auto_assign: true)
    assert user.valid?
  end

  test "rejects auto_assign for PM users" do
    user = build_user(organization: @pm_org, user_type: "property_manager", auto_assign: true)
    assert_not user.valid?
    assert user.errors[:auto_assign].any? { |e| e.include?("mitigation") }
  end

  test "auto_assigned scope returns only auto_assign users" do
    auto = build_user(email_address: "auto@test.com", auto_assign: true)
    auto.save!
    manual = build_user(email_address: "manual@test.com", auto_assign: false)
    manual.save!

    assert_includes User.auto_assigned, auto
    assert_not_includes User.auto_assigned, manual
  end

  # --- Guest type ---

  test "guest user type is valid for external org" do
    external = Organization.create!(name: "External", organization_type: "external")
    user = build_user(organization: external, user_type: "guest")
    assert user.valid?
    assert user.guest?
    assert_not user.mitigation_user?
    assert_not user.pm_user?
  end

  test "rejects non-guest type on external org" do
    external = Organization.create!(name: "External", organization_type: "external")
    user = build_user(organization: external, user_type: "manager")
    assert_not user.valid?
    assert user.errors[:user_type].any? { |e| e.include?("not valid for an external") }
  end

  test "rejects guest type on mitigation org" do
    user = build_user(organization: @mitigation_org, user_type: "guest")
    assert_not user.valid?
    assert user.errors[:user_type].any? { |e| e.include?("not valid for a mitigation") }
  end

  test "guest has empty default permissions" do
    external = Organization.create!(name: "External", organization_type: "external")
    user = build_user(organization: external, user_type: "guest")
    user.save!
    assert_equal [], user.permissions
    assert_not user.can?(:create_incident)
    assert_not user.can?(:manage_daily_logs)
  end

  # --- Active scope ---

  test "active scope excludes deactivated users" do
    active = build_user(email_address: "active@test.com")
    active.save!
    inactive = build_user(email_address: "inactive@test.com", active: false)
    inactive.save!

    assert_includes User.active, active
    assert_not_includes User.active, inactive
  end

  private

  def build_user(overrides = {})
    defaults = {
      organization: @mitigation_org,
      email_address: "user#{SecureRandom.hex(4)}@example.com",
      first_name: "Test",
      last_name: "User",
      user_type: "manager",
      password: "password123"
    }
    User.new(defaults.merge(overrides))
  end
end
