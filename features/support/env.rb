ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../../config/environment', __FILE__)

require 'cucumber/rails'
require 'capybara/rails'

# Use rack_test for speed; switch to :selenium if you need JS
Capybara.default_driver = :rack_test
Capybara.app = Rails.application

# Disable transactional fixtures if using DatabaseCleaner later
Cucumber::Rails::Database.javascript_strategy = :transaction

# Clean database between scenarios
Before do
  Product.delete_all
end


