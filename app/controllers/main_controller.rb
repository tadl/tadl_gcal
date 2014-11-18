class MainController < ApplicationController
  respond_to :html, :json, :js
  def home
  end

  def workorder
  end
  
  def new_staff_event
    @test = params[:test]
    @step = params[:step]
    if params[:previous_step]
      @previous_step = params[:previous_step]
    else
      @previous_step = '0'
    end
    @default_start = Time.at((Time.zone.now.to_f / 60.minutes).round * 60.minutes).in_time_zone('Eastern Time (US & Canada)')
    @default_end = @default_start + 1.hour
   respond_to do |format|
    format.js { render :layout => false }
   end
  end
  
end
