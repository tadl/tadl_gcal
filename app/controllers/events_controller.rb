class EventsController < ApplicationController
  require 'google/api_client'
  require 'google/api_client/client_secrets'
  require 'google/api_client/auth/installed_app'
  require 'tzinfo'
  before_action :authenticate_user!, :except => [:list]
  def list
    headers['Access-Control-Allow-Origin'] = '*'
    if params[:days_to_show]
      days_to_show = params[:days_to_show].to_i
    else
      days_to_show = 4
    end  
    events = []
    rooms.each do |r|      
  	  get_events = fetch_events(r[:id], r[:name], days_to_show)
      events = events + get_events
    end
    events = events.sort_by{|k| k[:start_time_raw]}
  	render :json =>{:events => events}	
  end

  def create
    summary = params[:title]
    description = params[:summary]
    attending = params[:attending]
    attendees = params[:attendees]
    responsible = params[:responsible]
    attending = params[:attending]
    phone = params[:phone]
    email = params[:email]
    room = params[:room]
    private_event = params[:private_event]
    room_arrangement = params[:room_arrangement]
    Time.zone = 'Eastern Time (US & Canada)'
    start_time = Time.zone.parse(params[:start])
    end_time = Time.zone.parse(params[:end])
    offset = timezone_offset()
    day_raw = Date.strptime(params[:day], '%m/%d/%Y')
    day = DateTime.new(day_raw.year, day_raw.month, day_raw.day) 
    start_date = DateTime.new(day.year, day.month, day.day, start_time.hour, start_time.min, start_time.sec, end_time.zone).in_time_zone(offset) 
    end_date = DateTime.new(day.year, day.month, day.day, end_time.hour, end_time.min, end_time.sec, end_time.zone).in_time_zone(offset)
    puts offset
    puts start_date
    cal_id = ''
    cal_name = ''
    rooms.each do |r|
      if r[:name] == room
        cal_id = r[:id]
        cal_name = r[:name]
      end
    end
    if private_event == 'true'
      summary += ' (PRIVATE)'
    end
    if !attending
      description += ', # Attending: ' + attending
    end
    if !responsible.empty?
      description += ', Responsible Party: ' + responsible
    end
    if !phone.empty?
      description += ', Phone: ' + phone
    end
    if !email.empty?
      description += ', Email: ' + email
    end
    if !room_arrangement.empty?
      description += ', Room Arrangement: ' + room_arrangement
    end

    attendees_array = attendees.map do |attendee|
      {
        "email" => attendee
      }
    end

    event = {
      'summary' => summary,
      'location' => cal_name,
      'start' => {
        'dateTime' => start_date.iso8601
      },
      'end' => {
        'dateTime' => end_date.iso8601
      },
      'description' => description,
      'attendees' => attendees_array 
    }
    client = create_gapi_client
    cal_api = client.discovered_api('calendar', 'v3')
    if params[:summary] && params[:summary]
      result = client.execute({
        :api_method => cal_api.events.insert,
        :parameters => {
          calendarId: cal_id,
          sendNotifications: true,
        },
        :body => JSON.dump(event),
        :headers => {'Content-Type' => 'application/json'}
      })
    end

    if result && result.data.id
      message = result.data
    else
      message = result.data
    end
    render :json =>{:message => message}
  end

  def fetch_events(cal_id, room_name, days_to_show)
    client = create_gapi_client()
    cal_api = client.discovered_api('calendar', 'v3')
    time_start = Time.zone.now.beginning_of_day
    time_end = time_start + (days_to_show *24*60*60)
    result = client.execute({
      api_method: cal_api.events.list,
      parameters: {
        calendarId: cal_id,
        timeMin: time_start.utc.iso8601,
        timeMax: time_end.utc.iso8601,
        singleEvents: true,
        orderBy: 'startTime',
        maxResults: 20
      }
    })

    events = []
    result.data.items.each do |e|
      if !e.summary.include?("(PRIVATE)") && !e.end.date
        event = {
          :name => e.summary.try(:gsub, /\n/, "").try(:gsub, '- advance', '').try(:strip),
          :description => e.description.try(:gsub, /\n/, "").try(:strip),
          :room => room_name,
          :id => e.id,
          :updated_time => e.updated,
          :day => is_today(e.start.dateTime.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e'),e.start.dateTime.in_time_zone('Eastern Time (US & Canada)')),
          :day_of_week => e.start.dateTime.in_time_zone('Eastern Time (US & Canada)').strftime('%A'),
          :start_time_raw => e.start.dateTime.in_time_zone('Eastern Time (US & Canada)'),
          :start_time => e.start.dateTime.in_time_zone('Eastern Time (US & Canada)').strftime('%l:%M %p'),
          :end_time_raw => e.end.dateTime.in_time_zone('Eastern Time (US & Canada)'),
          :end_time => e.end.dateTime.in_time_zone('Eastern Time (US & Canada)').strftime('%l:%M %p'),
        } 
        events.push(event)
      end
      if !e.summary.include?("(PRIVATE)") && e.end.date
        event ={
          :name => e.summary.try(:gsub, /\n/, "").try(:gsub, '- advance', '').try(:strip),
          :description => e.description.try(:gsub, /\n/, "").try(:strip),
          :room => room_name,
          :id => e.id,
          :updated_time => e.updated,
          :day => is_today(e.start.date.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e'),e.start.date.in_time_zone('Eastern Time (US & Canada)')),
          :day_of_week => e.start.date.in_time_zone('Eastern Time (US & Canada)').strftime('%A'),
          :start_time_raw => e.start.date.in_time_zone('Eastern Time (US & Canada)'),
          :start_time => e.start.date.in_time_zone('Eastern Time (US & Canada)').strftime('%l:%M %p'),
          :end_time_raw => e.end.date.in_time_zone('Eastern Time (US & Canada)'),
          :end_time => e.end.date.in_time_zone('Eastern Time (US & Canada)').strftime('%l:%M %p'),
          :all_day => 'true'
        }
        events.push(event)
      end  
    end
    return events
  end

  def is_today(date, raw_start)
    today = Time.zone.now.beginning_of_day.strftime('%B %e')
    tomorrow = (Time.zone.now.beginning_of_day + (1*24*60*60)).strftime('%B %e')
    day_of_week = raw_start.strftime('%A')
    if date == today
      return "Today"
    elsif date == tomorrow 
      return "Tomorrow"
    else
      return day_of_week + ', ' + date
    end
  end

  def find_users
    user_to_find = params[:user_to_find]
    client = create_directory_client()
    directory_api = client.discovered_api('admin', 'directory_v1')
    first_name_results = client.execute({
      api_method: directory_api.users.list,
      parameters: {
        domain: 'tadl.org',
        query: 'givenName%3A'+ user_to_find +'*'
      }
    })
    last_name_results = client.execute({
      api_method: directory_api.users.list,
      parameters: {
        domain: 'tadl.org',
        query: 'familyName%3A'+ user_to_find +'*'
      }
    })
    test = last_name_results.data.users + first_name_results.data.users
    test = test.uniq { |user| user.id }
    test = test.select {|user| user.includeInGlobalAddressList != false}
    render :json =>{:events => test}  
  end


end