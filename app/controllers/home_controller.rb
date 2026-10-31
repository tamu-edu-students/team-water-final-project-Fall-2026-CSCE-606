class HomeController < ApplicationController
  before_action :require_login

  def index
    @households = current_user.households.order(:name, :id)
  end
end
