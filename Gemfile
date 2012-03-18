source 'http://rubygems.org'

gem 'rails', '3.1.3'

# Mongo gems
gem 'mongoid', '~> 2.2.2'
gem 'mongoid_rails_migrations'

platform :ruby do
  gem 'mongo', '= 1.3.1'
  gem 'bson', '= 1.3.1'
  gem 'bson_ext', '= 1.3.1'
end

# Bushido gems
gem "devise"
gem "devise_bushido_authenticatable"
gem "bushido"
gem "uuid"

# External integrations
gem 'stripe'
gem 'pivotal-tracker'

# Error handling
gem 'airbrake'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.1.5'
  gem 'coffee-rails', '~> 3.1.1'
  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

group :test do
  # Pretty printed test output
  gem 'turn', '0.8.2', :require => false
end

gem "tane", :group => "development"
gem "rspec-rails", :group => "development"
gem "awesome_print", :group => "development"
