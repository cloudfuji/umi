class JenkinsController < ApplicationController
  before_filter :umi_authenticate_token!

  def notification
    puts params.inspect

    data = nil

    # Dealing with Jenkin's bad headers
    # "{\"name\":\"cloudfuji_master\",\"url\":\"job/cloudfuji_master/\",\"build\":{\"number\":452,\"phase\":\"STARTED\",\"url\":\"job/cloudfuji_master/452/\"}}"=>nil, "action"=>"notification", "controller"=>"jenkins", "format"=>"json"}
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

    event[:user_ido_id] = current_user.ido_id

    event[:data][:human] = "Build #{data['name']} ##{data['build']['number']} has #{event[:name]}"
    
    puts event.inspect

    Cloudfuji::Event.publish(event)

    User.all.collect do |user|
      Cloudfuji::User.notify(user.ido_id, "Build Update", event[:data][:human], "development")
    end

    render :json => "OK"
  end
end
