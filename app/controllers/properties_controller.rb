class PropertiesController < ApplicationController
  def index
    render inertia: "Properties/Index"
  end

  def new
    render inertia: "Properties/New"
  end

  def show
    @property = find_visible_property!(params[:id])
    render inertia: "Properties/Show"
  end
end
