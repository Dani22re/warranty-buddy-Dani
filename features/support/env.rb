require 'cucumber/rails'
require 'capybara/rails'
require 'capybara/cucumber'
require 'capybara/session'
require 'omniauth'
require 'omniauth/test'
require 'database_cleaner/active_record'

# Configure Capybara
Capybara.default_driver = :rack_test
Capybara.javascript_driver = :selenium_chrome_headless

# Configure drivers
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1280,720')
  
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

# Configure OmniAuth for testing
OmniAuth.config.test_mode = true
OmniAuth.config.logger = Rails.logger

# Configure test environment
Rails.application.config.force_ssl = false

# Load test helpers
require_relative 'oauth_test_helper'
require_relative 'test_helpers'

# Configure DatabaseCleaner
DatabaseCleaner.strategy = :transaction
DatabaseCleaner.clean_with(:truncation)

# Before each scenario
Before do
  # Clear any existing OAuth mocks
  clear_oauth_mocks
  # Start database cleaner
  DatabaseCleaner.start
  # Clear session
  Capybara.reset_sessions!
end

# After each scenario
After do
  # Clean up
  clear_oauth_mocks
  DatabaseCleaner.clean
  Capybara.reset_sessions!
end