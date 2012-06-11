require 'resque'
require 'resque_scheduler'
Dir["#{Rails.root}/app/jobs/*.rb"].each { |file| require file }

Resque.redis = YAML::load(ERB.new(IO.read("#{::Rails.root}/config/resque.yml")).result)[::Rails.env]
Resque.inline = ::Rails.env == "test"

puts "Resque inline? #{Resque.inline}"
