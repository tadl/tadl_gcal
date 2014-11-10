Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV["google_api_key"], ENV["google_api_secret"], :prompt => 'select_account', :scope => "userinfo.email,userinfo.profile"
end