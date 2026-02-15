class PropertiesController < ApplicationController
  def index
    render inertia: "Properties/Index"
  end

  def new
    render inertia: "Properties/New"
  end

  def show
    render inertia: "Properties/Show"
  end
end
