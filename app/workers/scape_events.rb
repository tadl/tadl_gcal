class CalendarScaper < ApplicationController
	include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence { minutely(5) }

	def perform()
    events = Array.new
    rooms = eval(ENV['rooms'])
    rooms.each do |r|      
  	  get_events = fetch_events(r[:id], r[:name])
      events = events + get_events
    end
    events = events.sort_by{|k| k['start_time_raw']}
    time = Time.now.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e at %l:%M %p')
		Rails.cache.write('events', events)
		Rails.cache.write('last_updated', time)
	end

	def fetch_events(cal_id, room_name)
    client = create_gapi_client()
    cal_api = client.discovered_api('calendar', 'v3')
    time_start = Time.zone.now.beginning_of_day
    # now plus how many days
    time_end = time_start + (5*24*60*60)
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
        event = Hash.new
        event['name'] = e.summary.try(:gsub, /\n/, "").try(:gsub, '- advance', '').try(:strip)
        event['description'] = e.description.try(:gsub, /\n/, "").try(:strip)
        event['room'] = room_name
        event['id'] = e.id
        event['updated_time'] = e.updated
        event['day'] = is_today(e.start.dateTime.in_time_zone('Eastern Time (US & Canada)').strftime('%B %e'),e.start.dateTime.in_time_zone('Eastern Time (US & Canada)'))
        event['day_of_week'] = e.start.dateTime.in_time_zone('Eastern Time (US & Canada)').strftime('%A')
        event['start_time_raw'] = e.start.dateTime.in_time_zone('Eastern Time (US & Canada)')
        event['start_time'] = e.start.dateTime.in_time_zone('Eastern Time (US & Canada)').strftime('%l:%M %p')
        event['end_time_raw'] = e.end.dateTime.in_time_zone('Eastern Time (US & Canada)')
        event['end_time'] = e.end.dateTime.in_time_zone('Eastern Time (US & Canada)').strftime('%l:%M %p')
        if !e.summary.include?("(PRIVATE)") && e.end.date
          event['all_day'] = 'true'
        end
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

end