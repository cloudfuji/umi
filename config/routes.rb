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
  resource(:pivotal ) { post :received     }
  resource(:github  ) { post :received     }
  resource(:stripe  ) { post :received     }
end
