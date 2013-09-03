Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer unless Rails.env.production?
  provider :lti, :oauth_credentials => { 'Caitlin Holman' => 'berlin' }
  provider :kerberos, uid_field: :username, fields: [ :username, :password ]
end
