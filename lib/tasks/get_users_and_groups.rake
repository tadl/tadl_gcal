desc "Get List of All Users"
task :get_users_and_groups => :environment do
	require 'google/api_client'
	require 'google/api_client/client_secrets'
	require 'google/api_client/auth/installed_app'

	controller_obj = ApplicationController.new

#Users
	client = controller_obj.create_directory_client()
	directory_api = client.discovered_api('admin', 'directory_v1')
	user_api_request = client.execute({
  	api_method: directory_api.users.list,
  	parameters: {
    	domain: 'tadl.org',
    	maxResults: 500
  	}
	})
	users = []
	user_api_request.data.users.each do |u|
		if !u['includeInGlobalAddressList'] == false && u['suspended'] == false
			user = Hash.new
			user['name'] = u['name']['fullName']
			user['first_name'] = u['name']['givenName'].downcase
			user['last_name'] = u['name']['familyName'].downcase
			user['email'] = u['primaryEmail']
			puts user['name']
			users = users.push(user)
		end	
	end
	Rails.cache.write("users", users)

#Groups
	group_api_request = client.execute({
  	api_method: directory_api.groups.list,
  	parameters: {
    	domain: 'tadl.org',
    	maxResults: 200
  	}
	})
	groups = []
	group_api_request.data.groups.each do |g|
		group = Hash.new
		group['name'] = g['name']
		group['search_name'] = g['name'].downcase
		group['email'] = g['email']
		puts group['name']
		groups = groups.push(group)
	end
	Rails.cache.write("groups", groups)
end