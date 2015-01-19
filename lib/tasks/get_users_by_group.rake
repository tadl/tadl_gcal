desc "Get List of All Users in All Groups"
task :get_users_by_group => :environment do
require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/installed_app'

controller_obj = ApplicationController.new

client = controller_obj.create_directory_client()
directory_api = client.discovered_api('admin', 'directory_v1')

groups = Rails.cache.read("groups")
groups_and_members = []

groups.each do |g|
	puts g['name'] + ':'
	g['members'] = []
	get_members = client.execute({
  		api_method: directory_api.members.list,
  		parameters: {
    		domain: 'tadl.org',
    		maxResults: 500,
    		groupKey: g['id'],
  		}
	})
	get_members.data.members.each do |m|
		g['members'].push(m['email'])
		puts m['email']
	end
	puts "--------"
end

Rails.cache.write("group_members", groups)
end

