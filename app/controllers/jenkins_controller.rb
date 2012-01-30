class JenkinsController < ApplicationController
  def notification
    puts params.inspect

    event = {}
    event[:category] = "build"
    event[:data]     = params[:build] || {}
    event[:data][:name] = params[:name]

    
    event[:name] = case params[:build][:phase].downcase
                   when "started"
                     "started"
                   when "finished"
                     params[:build][:status]
                   end

    puts event.inspect

    Bushido::Event.publish(event)

    render :json => "OK"
  end
end
