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

  match "/mailgun"   => 'mailgun#notification', :via => :post
  match "/jenkins"   => 'jenkins#notification', :via => :post
  match "/stripe"    => 'stripe#received',      :via => :post
  match "/events"    => 'events#create',        :via => [:post, :get]
  match "/ido_share" => 'events#script', :as => 'script'

  match '/external' => 'external#index'
  match '/external/:id' => 'external#show'  
  match '/proxy'=> 'external#proxy'

  resources(:auth_tokens)

  resource(:pivotal) do
    post :received
    get  :import
  end

  resource(:accounts)

  match '/' => 'accounts#index', :as => "root"
end
