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

  resource(:jenkins) { post :notification }
  resource(:github ) { post :received     }
end
