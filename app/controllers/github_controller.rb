class GithubsController < ApplicationController
  def received
    payload = params[:payload]

    event = {}
    event[:category] = "git"
    event[:name] = :received
    puts event.inspect
    event[:data] = payload



    Bushido::Event.publish(event)

    render :json => "OK"
  end
end

