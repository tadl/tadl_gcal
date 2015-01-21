class EventsController < ApplicationController
  require 'google/api_client'
  require 'google/api_client/client_secrets'
  require 'google/api_client/auth/installed_app'
  require 'tzinfo'
  require 'ice_cube'
  before_action :authenticate_user!, :except => [:list]
  
  def list
    headers['Access-Control-Allow-Origin'] = '*'
    events = Rails.cache.read('events')
    time = Rails.cache.read('last_updated')
    last_updated = 
  	render :json =>{:last_updated => time, :events => events}	
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
    recurrence_text = RecurringSelect.dirty_hash_to_rule(params[:reccurance])
    recurrence = recurrence_text.to_ical
    puts 'Reoccurs - ' + recurrence
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
        'dateTime' => start_date.iso8601,
        'timeZone' => 'America/Detroit'
      },
      'end' => {
        'dateTime' => end_date.iso8601,
        'timeZone' => 'America/Detroit'
      },
      'recurrence' => ['RRULE:' + recurrence],
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
      message = 'Something went wrong'
    end
    render :json =>{:message => message}
  end

  def find_users
    user_to_find = params[:user_to_find].downcase rescue nil
    users = Rails.cache.read("users")
    groups = Rails.cache.read("groups")
    results = []
    users.each do |u|
      if (u['first_name'].include? user_to_find) || (u['last_name'].include? user_to_find)
        results = results.push(u)
      end
    end
    groups.each do |g|
      if g['search_name'].include? user_to_find
        results = results.push(g)
      end
    end
    results.sort_by {|r| r['name']}
    render :json =>{:results => results}
  end
end