class GithubsController < ApplicationController
  def received
    payload = params[:payload]

    event = {}
    event[:category] = "git"
    event[:name] = :received

    event[:data] = payload

    puts event.inspect

    Bushido::Event.publish(event)

    render :json => "OK"
  end
end

