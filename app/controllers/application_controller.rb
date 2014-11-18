class ApplicationController < ActionController::Base
	require 'active_support/core_ext/numeric'
	helper_method :current_user	
 
  def rooms
		@rooms = eval(ENV['rooms'])
	end

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def create_gapi_client()
  	key_secret = 'notasecret'
    service_account_email = ENV['service_account_email']
    keypath = Rails.root.join('config', ENV['service_account_key_name']).to_s
    client = Google::APIClient.new(
      :application_name => 'tadl_gcal',
      :application_version => '1.0.0'
    )

    key = Google::APIClient::KeyUtils.load_from_pkcs12(keypath, key_secret)
    client.authorization = Signet::OAuth2::Client.new(
      :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
      :audience => 'https://accounts.google.com/o/oauth2/token',
      :scope => 'https://www.googleapis.com/auth/calendar',
      :issuer => service_account_email,
      :signing_key => key
    )
    client.authorization.fetch_access_token!
    return client
  end
end
