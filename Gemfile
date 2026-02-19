source "https://rubygems.org"

gem "rails", "~> 8.0.4"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"

# Frontend
gem "vite_rails"
gem "inertia_rails"

# Auth
gem "bcrypt", "~> 3.1.7"

# Background jobs + cache
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# PDF generation
gem "prawn"
gem "prawn-table"

# Boot performance
gem "bootsnap", require: false

# Windows timezone data
gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "minitest", "~> 5.25"
end

group :development do
  gem "web-console"
  gem "letter_opener_web"
end

group :test do
  gem "capybara"
  gem "capybara-playwright-driver"
end
