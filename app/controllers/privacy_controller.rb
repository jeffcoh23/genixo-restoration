class PrivacyController < ApplicationController
  allow_unauthenticated_access

  def show
    render inertia: "Public/Privacy"
  end
end
