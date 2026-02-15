class HomeController < ApplicationController
  def show
    render inertia: "Home"
  end
end
