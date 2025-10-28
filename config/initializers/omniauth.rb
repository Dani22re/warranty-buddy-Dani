Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           Rails.application.credentials.dig(:google, :client_id),
           Rails.application.credentials.dig(:google, :client_secret),
           scope: 'email,profile,gmail.readonly',
           access_type: 'offline',
           prompt: 'consent'
end
