source "https://rubygems.org"
ruby "3.3.0"

gem "rails", "~> 7.1.6"
gem "puma", ">= 5.0"

gem "pg", "~> 1.1"
gem "sidekiq", "~> 7.0"
gem "redis"
gem "connection_pool", "2.4.1"
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]
  gem "rspec-rails"
end

group :development do
  gem "foreman"
end
