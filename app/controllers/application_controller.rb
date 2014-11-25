class ApplicationController < ActionController::Base
	require 'active_support/core_ext/numeric'
	helper_method :current_user	
  helper_method :authenticate_user!

  def authenticate_user!
    if !current_user
      redirect_to root_url, :alert => 'You need to sign in for access to this page.'
    end
  end
 
  def rooms
		@rooms = eval(ENV['rooms'])
	end

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def create_gapi_client(user_email = '')
  	key_secret = 'notasecret'
    service_account_email = ENV['service_account_email']
    keypath = Rails.root.join('config', ENV['service_account_key_name']).to_s
    client = Google::APIClient.new(
      :application_name => 'tadl_gcal',
      :application_version => '1.0.0'
    )

    key = Google::APIClient::KeyUtils.load_from_pkcs12(keypath, key_secret)
    if user_email == ''
      client.authorization = Signet::OAuth2::Client.new(
        :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
        :audience => 'https://accounts.google.com/o/oauth2/token',
        :scope => 'https://www.googleapis.com/auth/calendar',
        :issuer => service_account_email,
        :signing_key => key
      )
      client.authorization.fetch_access_token!
    else
      asserter = Google::APIClient::JWTAsserter.new(service_account_email, 'https://www.googleapis.com/auth/calendar', key)
      client.authorization = asserter.authorize(user_email)
    end
    return client
  end

  def create_directory_client()
    key_secret = 'notasecret'
    service_account_email = ENV['service_account_email']
    keypath = Rails.root.join('config', ENV['service_account_key_name']).to_s
    client = Google::APIClient.new(
      :application_name => 'tadl_gcal',
      :application_version => '1.0.0'
    )
    key = Google::APIClient::KeyUtils.load_from_pkcs12(keypath, key_secret)
    # client.authorization = Signet::OAuth2::Client.new(
    #     :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
    #     :audience => 'https://accounts.google.com/o/oauth2/token',
    #     :scope => 'https://www.googleapis.com/auth/admin.directory.user.readonly',
    #     :issuer => service_account_email,
    #     :signing_key => key
    #   )
    # client.authorization.fetch_access_token!

    asserter = Google::APIClient::JWTAsserter.new(service_account_email, 'https://www.googleapis.com/auth/admin.directory.user.readonly', key)
    client.authorization = asserter.authorize(ENV['admin_email'])
    return client
  end
end
