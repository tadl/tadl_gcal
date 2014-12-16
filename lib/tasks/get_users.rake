desc "Get List of All Users"
task :get_users => :environment do
require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/installed_app'

controller_obj = ApplicationController.new

client = controller_obj.create_directory_client()
directory_api = client.discovered_api('admin', 'directory_v1')
first_name_results = client.execute({
  api_method: directory_api.users.list,
  parameters: {
    domain: 'tadl.org',
    maxResults: 500
  }
})
emails = ''
i = 0
first_name_results.data.users.each do |u|
	if !u['includeInGlobalAddressList'] == false && u['suspended'] == false  
		emails += u['primaryEmail'] + ' '
		i = i + 1
	end	
end

puts emails
puts i
end

