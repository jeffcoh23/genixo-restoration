class LoginRequestsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  # Public unauthenticated form — spam surface. Uses Rails.cache, so the test
  # swaps in a memory_store (test env default is :null_store, which never trips).
  rate_limit to: 5, within: 1.minute, only: :create,
    with: -> { redirect_to new_login_request_path, alert: "Too many requests. Please wait a minute and try again." }
  before_action :require_users_management_access, only: %i[approve reject]

  def new
    render inertia: "LoginRequest", props: {
      submit_path: login_requests_path,
      login_path: login_path,
      org_options: client_org_options
    }
  end

  def create
    login_request = LoginRequest.new(login_request_params)

    if login_request.save
      notify_reviewers(login_request)
      redirect_to new_login_request_path,
        notice: "Request received. Someone will review it and email you an invitation."
    else
      redirect_to new_login_request_path, inertia: { errors: login_request.errors.to_hash }
    end
  rescue ActiveRecord::RecordNotUnique
    # The partial unique index caught a double-submit race that slipped past the
    # model validation. A pending request already exists — tell the requester
    # the same success message rather than 500ing.
    redirect_to new_login_request_path,
      notice: "Request received. Someone will review it and email you an invitation."
  end

  def approve
    login_request = LoginRequest.find(params[:id])
    login_request.approve!(current_user)
    redirect_to users_path, notice: "Request approved — send #{login_request.email} an invitation."
  rescue ArgumentError
    redirect_to users_path, alert: "This request has already been reviewed."
  end

  def reject
    login_request = LoginRequest.find(params[:id])
    login_request.reject!(current_user, reason: params[:reason])
    redirect_to users_path, notice: "Request from #{login_request.email} rejected."
  rescue ArgumentError
    redirect_to users_path, alert: "This request has already been reviewed."
  end

  private

  def notify_reviewers(login_request)
    recipients = LoginRequest.reviewer_recipients
    # The request is still persisted and visible on the Users page; a missing
    # recipient set means no one is actively notified, worth flagging.
    Rails.logger.warn("[LoginRequest] no MANAGE_USERS recipients for request #{login_request.id}") if recipients.empty?
    recipients.each do |reviewer|
      LoginRequestMailer.new_request(reviewer, login_request).deliver_later
    end
  end

  def login_request_params
    params.permit(:email, :first_name, :last_name, :organization_id, :phone, :title, :message)
  end

  # PM (client) orgs the requester can select. Public endpoint, so it isn't
  # scoped to a mitigation org — fine while there's a single provider; revisit
  # (scope per provider) if a second real mitigation org onboards.
  def client_org_options
    Organization.where(organization_type: "property_management").order(:name)
                .map { |o| { id: o.id, name: o.name } }
  end

  def require_users_management_access
    raise ActiveRecord::RecordNotFound unless can_manage_users?
  end
end
