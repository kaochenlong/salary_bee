class DashboardController < ApplicationController
  def index
    @companies = Current.user.companies.includes(:users)
  end
end