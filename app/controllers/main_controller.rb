class MainController < ApplicationController
  respond_to :html, :json, :js
  def home
  end

  def workorder
  end
  
  def new_staff_event
    @test = params[:test]
    @step = params[:step]
   respond_to do |format|
    format.js { render :layout => false }
   end
  end
  
end
