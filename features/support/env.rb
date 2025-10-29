require 'cucumber/rails'
require 'capybara/rails'
require 'capybara/cucumber'
require 'capybara/session'
require 'omniauth'
require 'omniauth/test'

# Configure Capybara
Capybara.default_driver = :rack_test
Capybara.javascript_driver = :selenium_chrome_headless

# Configure OmniAuth for testing
OmniAuth.config.test_mode = true
OmniAuth.config.logger = Rails.logger

# Configure test environment
Rails.application.config.force_ssl = false

# Load test helpers
require_relative 'oauth_test_helper'
require_relative 'test_helpers'

# Before each scenario
Before do
  # Clear any existing OAuth mocks
  clear_oauth_mocks
  # Clear database
  Product.destroy_all
  # Clear session
  Capybara.reset_sessions!
end

# After each scenario
After do
  # Clean up
  clear_oauth_mocks
  Product.destroy_all
  Capybara.reset_sessions!
end