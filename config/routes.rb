Rails.application.routes.draw do
  root "dashboard#index"

  # OAuth callback & failure
  get '/auth/:provider/callback', to: 'dashboard#google_auth'
  get '/auth/failure', to: redirect('/')

  # Dashboard routes
  get "dashboard/index"
  get "dashboard/connect_gmail"
  get "dashboard/upload"
  post "/upload", to: "dashboard#upload"
  get "dashboard/api_warranties"
  get "dashboard/api_health"
  get "dashboard/reset"
  post "/disconnect_gmail", to: "dashboard#disconnect_gmail"
end
