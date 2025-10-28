Rails.application.routes.draw do
  # Root route - main dashboard page
  root "dashboard#index"

  # Connect Gmail (mock)
  post "connect_gmail", to: "dashboard#connect_gmail"

  # Upload a new receipt
  post "upload", to: "dashboard#upload"

  # API routes
  get "api/warranties", to: "dashboard#api_warranties"
  get "api/health", to: "dashboard#api_health"

  # Reset (for mock/testing)
  post "reset", to: "dashboard#reset"

  # Rails health check (default)
  get "up" => "rails/health#show", as: :rails_health_check
end
