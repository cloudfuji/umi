begin
  Rails.application.routes.draw do
    cloudfuji_routes
  end
rescue => e
  puts "Error loading the Cloudfuji routes:"
  puts "#{e.inspect}"
end

Umi::Application.routes.draw do
  devise_for :users

  match "/mailgun" => 'mailgun#notification', :via => :post
  match "/jenkins" => 'jenkins#notification', :via => :post
  match "/stripe"  => 'stripe#received',      :via => :post
  match "/events"  => 'events#create',        :via => :post

  resource(:pivotal) do
    post :received
    get  :import
  end

  resource(:accounts)

  match '/' => 'accounts#index', :as => "root"
end
