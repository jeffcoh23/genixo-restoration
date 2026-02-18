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

  test "defaults timezone to America/Chicago" do
    user = User.new
    assert_equal "America/Chicago", user.timezone
  end

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
