# Gemfile

ruby "3.2.2"

source "https://rubygems.org"

# --- Core Rails stack ---
gem "rails", "~> 8.1.0"
gem "puma", ">= 5.0"                 # Web server
gem "pg", "~> 1.1"                   # PostgreSQL
gem "propshaft"                      # Asset pipeline
gem "importmap-rails"               # JS via import maps
gem "turbo-rails"                   # Hotwire Turbo
gem "stimulus-rails"                # Hotwire Stimulus
gem "jbuilder"                      # JSON builders

# Windows / JRuby tzdata shim (safe to keep; ignored on Linux)
gem "tzinfo-data", platforms: %i[windows jruby]

# --- Caching, queues, and Action Cable (Rails 8 defaults) ---
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# --- Performance / deployment helpers ---
gem "bootsnap", require: false
gem "kamal", require: false          # (Optional) Docker deploys
gem "thruster", require: false       # Puma HTTP compression/X-Sendfile

# --- Images / variants (Active Storage use) ---
gem "image_processing", "~> 1.2"

# --- App features used in production ---
gem "omniauth", "~> 2.1"
gem "omniauth-rails_csrf_protection", "~> 1.0"
gem "omniauth-google-oauth2", "~> 1.1"
gem "google-api-client", "~> 0.53"

gem "sidekiq"                        # Only if you intend to run background jobs
gem "gemini-ai", "~> 4.3.0"
gem "nokogiri"
gem "mail"
gem "pdf-reader"
gem "rtesseract"                     # Needs the tesseract-ocr binary (see §8)
gem "chronic"
gem "money"
gem "icalendar"

# --- Development & Test only ---
group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false

  gem "rspec-rails", "~> 6.0"
  gem "cucumber-rails", require: false
  gem "factory_bot_rails"

  # Only for local/dev env var loading. Heroku uses Config Vars.
  gem "dotenv-rails"
end

group :development do
  gem "web-console"
  gem "rerun"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "simplecov", require: false
  gem "database_cleaner-active_record"
end
gem "sqlite3", "~> 2.1"
