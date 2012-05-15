class CloudfujiEmailHooks < Cloudfuji::EventObserver

  def mail_simple
    puts "YAY!"
    puts params.inspect
  end

end
