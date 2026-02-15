class IncidentsController < ApplicationController
  def index
    render inertia: "Incidents/Index"
  end

  def new
    render inertia: "Incidents/New"
  end

  def show
    render inertia: "Incidents/Show"
  end
end
