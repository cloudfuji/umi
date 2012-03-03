class JenkinsController < ApplicationController
  def notification
    puts params.inspect

    data = nil

    # Dealing with Jenkin's bad headers
    # "{\"name\":\"bushido_master\",\"url\":\"job/bushido_master/\",\"build\":{\"number\":452,\"phase\":\"STARTED\",\"url\":\"job/bushido_master/452/\"}}"=>nil, "action"=>"notification", "controller"=>"jenkins", "format"=>"json"}
    params.keys.each do |key|
      begin
        data = JSON(key)
        break if data[:build]
      rescue
        puts "key: #{key} not deserializable from json"
      end
    end

    if data.nil? || data[:build].nil?
      puts "Returning blank due to badly formatted data:"
      puts data.inspect
    end

    event               = {}
    event[:category]    = "build"
    event[:data]        = data["build"] || {}
    event[:data][:name] = data["name"]


    event[:name] = case data["build"]["phase"].downcase
                   when "started"
                     "started"
                   when "finished"
                     data["build"]["status"]
                   end

    puts event.inspect

    event[:data][:human] = "Build #{data['name']} ##{data['build']['number']} has #{event[:name]}"

    Bushido::Event.publish(event)

    User.all.collect do |user|
      Bushido::User.notify(user.ido_id, "Build Update", event[:data][:human], "development")
    end

    render :json => "OK"
  end
end
