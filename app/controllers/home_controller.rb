class HomeController < ApplicationController
  def generate
    @overview = Overview.new
    @overview.sprint_order = params[:sprint_order]
    @overview.sprint_start_date = params[:sprint_start_date]
    @overview.sprint_end_date = params[:sprint_end_date]
    @overview.release_order = params[:release_order]
    @overview.generateOverviews
  end
end
