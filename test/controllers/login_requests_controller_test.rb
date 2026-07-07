require "test_helper"
require "minitest/mock"

class LoginRequestsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "Test", last_name: "Tech", password: "password123")
    pm_org = Organization.create!(name: "Greystar", organization_type: "property_management")
    @pm_user = User.create!(organization: pm_org, user_type: "property_manager",
      email_address: "pm@greystar.com", first_name: "Test", last_name: "PM", password: "password123")
  end

  def valid_params(email: "dan@acme.com")
    { email: email, first_name: "Dan", last_name: "Hutson", company_name: "Acme PM" }
  end

  # --- Public form ---

  test "request-access page renders without authentication" do
    get new_login_request_path
    assert_response :success
  end

  test "create saves the request and emails MANAGE_USERS holders" do
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test

    assert_difference -> { LoginRequest.count }, 1 do
      # @manager holds MANAGE_USERS; @tech and @pm_user do not
      assert_enqueued_emails 1 do
        post login_requests_path, params: valid_params
      end
    end
    assert_redirected_to new_login_request_path
    assert flash[:notice].present?
  ensure
    ActiveJob::Base.queue_adapter = original_adapter
  end

  test "create with invalid params redirects back with errors and sends nothing" do
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test

    assert_no_difference -> { LoginRequest.count } do
      assert_no_enqueued_emails do
        post login_requests_path, params: { email: "", first_name: "", last_name: "" }
      end
    end
    assert_redirected_to new_login_request_path
  ensure
    ActiveJob::Base.queue_adapter = original_adapter
  end

  test "create is rate limited" do
    # rate_limit captures the controller's cache_store at class-definition time,
    # and the test env's :null_store never counts (increment returns nil).
    # Swapping Rails.cache after boot can't reach the captured store — stub
    # increment on that store instead so the limiter actually counts.
    require "minitest/mock"
    counts = Hash.new(0)
    store = LoginRequestsController.cache_store

    store.stub(:increment, ->(key, amount = 1, **) { counts[key] += amount }) do
      5.times do |i|
        post login_requests_path, params: valid_params(email: "person#{i}@acme.com")
        assert flash[:notice].present?, "request #{i + 1} should be accepted"
      end

      assert_no_difference -> { LoginRequest.count } do
        post login_requests_path, params: valid_params(email: "person6@acme.com")
      end
      assert_redirected_to new_login_request_path
      assert flash[:alert].present?, "sixth request within a minute should be rejected"
    end
  end

  test "a duplicate pending request that races past validation is handled gracefully" do
    LoginRequest.create!(valid_params(email: "race@acme.com"))

    # Simulate the race: validation passes on a stale read, but the partial
    # unique index rejects the insert. The controller must treat the
    # RecordNotUnique as success, not 500.
    racer = LoginRequest.new(valid_params(email: "race@acme.com"))
    racer.define_singleton_method(:save) { raise ActiveRecord::RecordNotUnique, "duplicate" }

    LoginRequest.stub(:new, racer) do
      post login_requests_path, params: valid_params(email: "race@acme.com")
    end

    assert_redirected_to new_login_request_path
    assert flash[:notice].present?
    assert_equal 1, LoginRequest.where(email: "race@acme.com").count
  end

  # --- Review actions ---

  test "manager can approve a pending request" do
    request = LoginRequest.create!(valid_params)
    login_as @manager

    patch approve_login_request_path(request)
    assert_redirected_to users_path
    assert request.reload.approved?
    assert_equal @manager, request.reviewed_by_user
  end

  test "manager can reject with a reason" do
    request = LoginRequest.create!(valid_params)
    login_as @manager

    patch reject_login_request_path(request), params: { reason: "Unknown company" }
    assert request.reload.rejected?
    assert_equal "Unknown company", request.rejection_reason
  end

  test "approving an already-reviewed request redirects with an alert" do
    request = LoginRequest.create!(valid_params)
    request.reject!(@manager)
    login_as @manager

    patch approve_login_request_path(request)
    assert_redirected_to users_path
    assert flash[:alert].present?
    assert request.reload.rejected?, "status must not change"
  end

  test "technician cannot review requests" do
    request = LoginRequest.create!(valid_params)
    login_as @tech

    patch approve_login_request_path(request)
    assert_response :not_found
    assert request.reload.pending?
  end

  test "PM user cannot review requests" do
    request = LoginRequest.create!(valid_params)
    login_as @pm_user

    patch approve_login_request_path(request)
    assert_response :not_found
  end

  test "unauthenticated review is rejected" do
    request = LoginRequest.create!(valid_params)
    patch approve_login_request_path(request)
    assert_redirected_to login_path
    assert request.reload.pending?
  end

  private

  def login_as(user)
    post login_path, params: { email_address: user.email_address, password: "password123" }
  end
end
