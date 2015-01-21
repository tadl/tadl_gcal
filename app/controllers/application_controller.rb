class ApplicationController < ActionController::Base
	require 'active_support/core_ext/numeric'
	helper_method :current_user	
  helper_method :authenticate_user!
  helper_method :timezone_offset

  def authenticate_user!
    if !current_user
      redirect_to root_url, :alert => 'You need to sign in for access to this page.'
    end
  end

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def timezone_offset
    tz = TZInfo::Timezone.get('America/New_York')
    off_set = tz.current_period.utc_total_offset.to_i / 60 / 60
    return off_set
  end  

  def create_gapi_client
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
      :scope => ['https://www.googleapis.com/auth/calendar', 'https://www.googleapis.com/auth/admin.directory.group.member.readonly'],
      :issuer => service_account_email,
      :signing_key => key
    )
    client.authorization.fetch_access_token!
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

    permissions = ['https://www.googleapis.com/auth/admin.directory.user.readonly', 
      'https://www.googleapis.com/auth/admin.directory.group.readonly',
      'https://www.googleapis.com/auth/admin.directory.group.member.readonly'
    ]
    key = Google::APIClient::KeyUtils.load_from_pkcs12(keypath, key_secret)
    asserter = Google::APIClient::JWTAsserter.new(service_account_email, permissions, key)
    client.authorization = asserter.authorize(ENV['admin_email'])
    return client
  end
end
