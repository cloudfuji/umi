source 'http://rubygems.org'

gem 'bundler_local_development', :group => :development, :require => false
begin
  require 'bundler_local_development'
rescue LoadError
end

gem 'rails', '3.2.0'

# Mongo gems
gem 'mongoid', '~> 2.2.2'
gem 'mongoid_rails_migrations'

platform :ruby do
  gem 'mongo', '= 1.3.1'
  gem 'bson', '= 1.3.1'
  gem 'bson_ext', '= 1.3.1'
end

# Cloudfuji gems
gem "devise"
gem "devise_cloudfuji_authenticatable"
gem "cloudfuji"
gem "uuid"
gem "tane", :group => "development"

# External integrations
gem 'stripe'
gem 'pivotal-tracker'
gem 'mailchimp', "~> 0.0.7.alpha"

# Error handling
gem 'airbrake'
gem 'airbrake_user_attributes'

# Background workers
gem 'resque', '~> 1.20.0'
gem 'resque-scheduler'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

group :test do
  # Pretty printed test output
  gem 'turn', '0.8.2', :require => false
end

group :development, :test do
  gem "rspec-rails", :group => "development"
  gem "awesome_print", :group => "development"
  unless ENV["CI"]
    # gem 'ruby-debug', :platform => :mri_18
    # gem (RUBY_VERSION == "1.9.2" ? 'ruby-debug19' : 'debugger'), :platform => :mri_19
  end
end
