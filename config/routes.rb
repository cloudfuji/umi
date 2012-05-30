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

  match "/mailgun/notification" => 'mailgun#notification', :via => :post
  match "/jenkins/notification" => 'jenkins#notification', :via => :post
  match "/stripe/received"      => 'stripe#received',      :via => :post
  match "/github/received"      => 'github#received',      :via => :post
  match "/events"               => 'events#create',        :via => [:post, :get]
  match "/ido_share"            => 'events#script',        :as => 'script'

  resources(:auth_tokens)

  resource(:pivotal) do
    post :received
    get  :import
  end

  resource(:accounts)

  match '/' => 'accounts#index', :as => "root"
end
