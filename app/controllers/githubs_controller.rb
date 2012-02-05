class GithubsController < ApplicationController
  def received
    puts params.inspect
    payload = params[:payload]
    puts payload.inspect
    payload = Bushido::Utils.normalize_keys(JSON(payload)) if payload.is_a?(String)
    puts payload.inspect

    event = {}
    event[:category] = "git"
    event[:name] = :received

    event[:data] = payload

    repo      = payload[:repository]
    repo_name = repo[:name]
    commits   = payload[:commits]
    actor     = commits.last[:author][:name] || commits.last[:author][:email]
    url       = commits.last[:url]
    message   = commits.last[:message]
    branch    = payload[:ref].split("/").last

    event[:data][:human] = "#{actor} pushed to #{repo_name}/#{branch}, saying '#{message}' -> See more at #{url}"

    puts event.inspect

    Bushido::Event.publish(event)

    render :json => "OK"
  end
end

