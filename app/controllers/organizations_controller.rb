class OrganizationsController < ApplicationController
  def index
    render inertia: "Organizations/Index"
  end

  def new
    render inertia: "Organizations/New"
  end

  def show
    render inertia: "Organizations/Show"
  end
end
