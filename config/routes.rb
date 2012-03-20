begin
  Rails.application.routes.draw do
    bushido_routes
  end
rescue => e
  puts "Error loading the Bushido routes:"
  puts "#{e.inspect}"
end

Umi::Application.routes.draw do
  devise_for :users

  resource(:mailgun ) { post :notification }
  resource(:jenkins ) { post :notification }
  resource(:github  ) { post :received     }
  resource(:stripe  ) { post :received     }

  resource(:pivotal ) do
    post :received
    get  :import
  end

  resource(:accounts)

  match '/' => 'accounts#index', :as => "root"
end
