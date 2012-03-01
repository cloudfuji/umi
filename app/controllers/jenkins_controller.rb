class JenkinsController < ApplicationController
  def notification
    puts params.inspect

    # Because of the weird Jenkins header format...
    data = JSON(params[:key], :symbolize_names => true)

    puts data.inspect

    event               = {}
    event[:category]    = "build"
    event[:data]        = data[:build] || {}
    event[:data][:name] = data[:name]


    event[:name] = case data[:build][:phase].downcase
                   when "started"
                     "started"
                   when "finished"
                     data[:build][:status]
                   end

    puts event.inspect

    event[:data][:human] = "Build #{data[:name]} ##{data[:build][:number]} has #{event[:name]}"

    Bushido::Event.publish(event)

    User.all.collect do |user|
      Bushido::User.notify(user.ido_id, "Build Update", event[:data][:human], "development")
    end

    render :json => "OK"
  end
end
