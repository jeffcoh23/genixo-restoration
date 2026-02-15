class UsersController < ApplicationController
  def index
    render inertia: "Users/Index"
  end

  def show
    render inertia: "Users/Show"
  end
end
