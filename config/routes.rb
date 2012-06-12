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

  match "/events"                  => 'events#create',              :via => [:post, :get]
  match "/ido_share"               => 'events#script',              :as => 'script'
  match '/external'                => 'external#index'
  match '/external/:id'            => 'external#show'  
  match '/proxy'                   => 'external#proxy'
  match "/mailgun/notification"    => 'mailgun#notification',       :via => :post
  match "/mailchimp/notification"  => 'mailchimp#notification',     :via => :post
  match "/mailchimp/notification"  => 'mailchimp#confirm_webhook',  :via => :get
  match "/mailchimp/refresh_lists" => 'mailchimp#refresh_lists',    :via => :get
  match "/jenkins/notification"    => 'jenkins#notification',       :via => :post
  match "/stripe/received"         => 'stripe#received',            :via => :post
  match "/github/received"         => 'github#received',            :via => :post
  match "/pivotal/received"        => 'pivotal#received',           :via => :post
  match "/pivotal/import"          => 'pivotal#import',             :via => :get

  resources :auth_tokens 
  resource  :accounts 
  resources :imap_accounts, :only => [:create, :destroy]
  
  match '/' => 'accounts#index', :as => "root"
end
