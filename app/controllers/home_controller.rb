class HomeController < ApplicationController
  def generate
    @overview = Overview.new
    @overview.sprint_order = params[:sprint_order]
    @overview.sprint_start_date = params[:sprint_start_date]
    @overview.sprint_end_date = params[:sprint_end_date]
    @overview.release_name = params[:release_name]
    @overview.generateOverviews
  end
end
