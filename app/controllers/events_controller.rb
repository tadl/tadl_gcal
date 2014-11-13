class EventsController < ApplicationController
  require 'google/api_client'
  require 'google/api_client/client_secrets'
  require 'google/api_client/auth/installed_app'

  def list
    if params[:days_to_show]
      days_to_show = params[:days_to_show].to_i
    else
      days_to_show = 3
    end  
    headers['Access-Control-Allow-Origin'] = '*'      
  	thirlby = fetch_events('tadl.org_3438383133313638343937@resource.calendar.google.com', 'Thirlby Room', days_to_show)
    mcguire = fetch_events('tadl.org_2d3338313731393032333233@resource.calendar.google.com', 'McGuire Room', days_to_show)
    nelson = fetch_events('tadl.org_393731343335322d373338@resource.calendar.google.com', 'Nelson Room', days_to_show)
    youth = fetch_events('tadl.org_35303232393338322d373135@resource.calendar.google.com', 'Youth Story Room', days_to_show)
    study_d = fetch_events('tadl.org_3934353735303033393235@resource.calendar.google.com', 'Study Room D', days_to_show)
    events = thirlby + mcguire + nelson + youth + study_d
    events = events.sort_by{|k| k[:start_time_raw]}
  	render :json =>{:events => events}	
  end

  def fetch_events(cal_id, room_name, days_to_show)
    key_secret = 'notasecret'
    service_account_email = ENV['service_account_email']
    keypath = Rails.root.join('config', ENV['service_account_key_name']).to_s
    client = Google::APIClient.new(
      :application_name => 'tadl_gcal',
      :application_version => '1.0.0'
    )
    cal_api = client.discovered_api('calendar', 'v3')

    key = Google::APIClient::KeyUtils.load_from_pkcs12(keypath, key_secret)
    client.authorization = Signet::OAuth2::Client.new(
      :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
      :audience => 'https://accounts.google.com/o/oauth2/token',
      :scope => 'https://www.googleapis.com/auth/calendar',
      :issuer => service_account_email,
      :signing_key => key
    )
    client.authorization.fetch_access_token!
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
        maxResults: 10
      }
    })

    events = []
    result.data.items.each do |e|
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
end
