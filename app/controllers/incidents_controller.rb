class IncidentsController < ApplicationController
  def index
    render inertia: "Incidents/Index"
  end

  def new
    render inertia: "Incidents/New"
  end

  def show
    @incident = find_visible_incident!(params[:id])
    render inertia: "Incidents/Show"
  end
end
