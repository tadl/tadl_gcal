require 'nokogiri'
require 'time'
require 'google_calendar'

Google.module_eval do
	def Event	
		def self.new_from_xml(xml, calendar) #:nodoc:
      		xml.xpath("gd:when").collect do |event_time|
        	Event.new(:id           => parse_id(xml),
                  :calendar     => calendar,
                  :raaaw_xml      => 'hello',
                  :title        => xml.at_xpath("xmlns:title").content,
                  :content      => xml.at_xpath("xmlns:content").content,
                  :where        => xml.at_xpath("gd:where")['valueString'],
                  :start_time   => (event_time.nil? ? nil : event_time['startTime']),
                  :endy_time     => (event_time.nil? ? nil : event_time['endTime']),
                  :transparency => xml.at_xpath("gd:transparency")['value'].split('.').last,
                  :quickadd     => (xml.at_xpath("gCal:quickadd") ? (xml.at_xpath("gCal:quickadd")['quickadd']) : nil),
                  :html_link    => xml.at_xpath('//xmlns:link[@title="alternate" and @rel="alternate" and @type="text/html"]')['href'],
                  :published    => xml.at_xpath("xmlns:published").content,
                  :updated      => xml.at_xpath("xmlns:updated").content )
      		end
    	end
    	   def self.parse_id(xml) #:nodoc:
      id = xml.at_xpath("gCal:uid")['value'].split('@').first

      # Check if this event came from an apple program (ios, iCal, Calendar, etc)
      # Id format ex: E52411E2-8DB9-4A26-AD5A-8B6104320D3C
      if id.match( /[0-9A-Z]{8}-([0-9A-Z]{4}-){3}[0-9A-Z]{12}/ )
        # Use the ID field instead of the UID which apple overwrites for its own purposes.
        # TODO With proper testing, this should be way to parse all event id's
        id = xml.at_xpath("xmlns:id").content.split('/').last
      end

      return id
    end
end
end