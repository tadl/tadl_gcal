class EventsController < ApplicationController
require 'google_calendar'
require 'dotenv'

  def all
    if params[:days_from_now]
      days_from_now = params[:days_from_now].to_i
    else
      days_from_now = 1
    end  
    headers['Access-Control-Allow-Origin'] = '*'      
  	thirlby = fetch_events('tadl.org_3438383133313638343937@resource.calendar.google.com', 'Thirlby Room', days_from_now)
    mcguire = fetch_events('tadl.org_2d3338313731393032333233@resource.calendar.google.com', 'McGuire Room', days_from_now)
    nelson = fetch_events('tadl.org_393731343335322d373338@resource.calendar.google.com', 'Nelson Room', days_from_now)
    youth = fetch_events('tadl.org_35303232393338322d373135@resource.calendar.google.com', 'Youth Story Room', days_from_now)
    study_d = fetch_events('tadl.org_3934353735303033393235@resource.calendar.google.com', 'Study Room D', days_from_now)
    events = thirlby + mcguire + nelson + youth + study_d
    events.each do |e|
      events.each do |c|
        if e[:id] == c[:id] && e[:name] != c[:name]
          if e[:updated_time] > c[:updated_time]
            events.delete(c)
          else
            events.delete(e)
          end
        end
      end
    end
    events = events.sort_by{|k| k[:start_time_raw]}
  	render :json =>{:days_from_now => days_from_now, :events => events}	
  end

  def fetch_events(cal_id, room_name, days_from_now)
    events = []
    start_date = Date.today.in_time_zone
    end_date =  start_date + (days_from_now *24*60*60)
    cal = Google::Calendar.new(:username => ENV['username'], :password => ENV['password'], :calendar => cal_id, :app_name =>'alpine-freedom-720')
    cal_events = cal.find_events_in_range(start_date, end_date)
      Array(cal_events).each_with_index do |e|
        if e.status != 'event.canceled'
          event = {
            :name => e.title.gsub('- advance',''),
            :id => e.id,
            :updated_time => e.updated_time,
            :day => is_today(e.start_time.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e')),
            :start_time_raw => e.start_time,
            :start_time => e.start_time.in_time_zone('Eastern Time (US & Canada)').strftime('%l:%M %p'),
            :end_time_raw => e.end_time,
            :end_time => e.end_time.in_time_zone('Eastern Time (US & Canada)').strftime('%l:%M %p'),
            :room => room_name
          }
          events.push(event)
        end
      end rescue nil
    return events
  end

  def is_today(date)
    today = Date.today.in_time_zone.strftime('%B %e')
    tomorrow = (Date.today.in_time_zone + (1*24*60*60)).strftime('%B %e')
    if date == today
      return "Today"
    elsif date == tomorrow 
      return "Tomorrow"
    else
      return date
    end
  end



end
