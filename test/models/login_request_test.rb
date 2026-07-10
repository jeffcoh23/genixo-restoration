require "test_helper"

class LoginRequestTest < ActiveSupport::TestCase
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @pm_org = Organization.create!(name: "Acme PM", organization_type: "property_management")
  end

  def valid_attrs(email: "dan@acme.com")
    { email: email, first_name: "Dan", last_name: "Hutson", organization: @pm_org, phone: "(210) 555-0100" }
  end

  test "valid with email and names" do
    assert LoginRequest.new(valid_attrs).valid?
  end

  test "requires email, first name, last name" do
    request = LoginRequest.new
    refute request.valid?
    assert request.errors[:email].any?
    assert request.errors[:first_name].any?
    assert request.errors[:last_name].any?
  end

  test "rejects malformed email" do
    refute LoginRequest.new(valid_attrs(email: "not-an-email")).valid?
  end

  test "caps field lengths on the public form" do
    request = LoginRequest.new(valid_attrs.merge(
      first_name: "a" * 101, message: "m" * 2001, phone: "5" * 51
    ))
    refute request.valid?
    assert request.errors[:first_name].any?
    assert request.errors[:message].any?
    assert request.errors[:phone].any?
  end

  test "requires an organization" do
    request = LoginRequest.new(valid_attrs.except(:organization))
    refute request.valid?
    assert request.errors[:organization_id].any?
  end

  test "requires a phone number" do
    request = LoginRequest.new(valid_attrs.except(:phone))
    refute request.valid?
    assert request.errors[:phone].any?
  end

  test "rejects a non-property-management organization" do
    request = LoginRequest.new(valid_attrs.merge(organization: @genixo))
    refute request.valid?
    assert request.errors[:organization_id].any?
  end

  test "snapshots company_name from the chosen organization" do
    request = LoginRequest.create!(valid_attrs)
    assert_equal "Acme PM", request.company_name
  end

  test "normalizes email to lowercase" do
    request = LoginRequest.create!(valid_attrs(email: "  Dan@Acme.COM "))
    assert_equal "dan@acme.com", request.email
  end

  test "disallows a second pending request for the same email" do
    LoginRequest.create!(valid_attrs)
    dup = LoginRequest.new(valid_attrs)
    refute dup.valid?
    assert dup.errors[:email].any?
  end

  test "allows a new request after the previous one was rejected" do
    first = LoginRequest.create!(valid_attrs)
    first.reject!(@manager)
    assert LoginRequest.new(valid_attrs).valid?
  end

  test "partial unique index rejects a second pending request at the DB level" do
    LoginRequest.create!(valid_attrs(email: "race@acme.com"))
    dup = LoginRequest.new(valid_attrs(email: "race@acme.com"))
    # Bypass the model validation to prove the DB index is the backstop.
    assert_raises(ActiveRecord::RecordNotUnique) { dup.save(validate: false) }
  end

  test "approve! stamps reviewer, time, and status" do
    request = LoginRequest.create!(valid_attrs)
    request.approve!(@manager)
    assert request.approved?
    assert_equal @manager, request.reviewed_by_user
    assert request.reviewed_at.present?
  end

  test "reject! records an optional reason" do
    request = LoginRequest.create!(valid_attrs)
    request.reject!(@manager, reason: "Unknown company")
    assert request.rejected?
    assert_equal "Unknown company", request.rejection_reason
  end

  test "approve! raises on an already-reviewed request" do
    request = LoginRequest.create!(valid_attrs)
    request.reject!(@manager)
    assert_raises(ArgumentError) { request.approve!(@manager) }
  end

  test "reviewer_recipients returns active mitigation users with MANAGE_USERS only" do
    office = User.create!(organization: @genixo, user_type: "office_sales",
      email_address: "office@genixo.com", first_name: "Office", last_name: "User", password: "password123")
    tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "Tech", last_name: "User", password: "password123")
    inactive = User.create!(organization: @genixo, user_type: "manager", active: false,
      email_address: "gone@genixo.com", first_name: "Gone", last_name: "Manager", password: "password123")
    pm_org = Organization.create!(name: "Greystar", organization_type: "property_management")
    pm = User.create!(organization: pm_org, user_type: "property_manager",
      email_address: "pm@greystar.com", first_name: "PM", last_name: "User", password: "password123")

    recipients = LoginRequest.reviewer_recipients
    assert_includes recipients, @manager
    assert_includes recipients, office, "office_sales holds MANAGE_USERS by default"
    refute_includes recipients, tech
    refute_includes recipients, inactive
    refute_includes recipients, pm
  end
end
