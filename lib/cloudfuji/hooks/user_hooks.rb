class CloudfujiUserHooks < Cloudfuji::EventObserver
  def user_added
    puts "Adding a new user with incoming data #{params.inspect}"
    puts "Devise username column: #{::Devise.cas_username_column}="
    puts "Setting username to: #{params['data'].try(:[], 'ido_id')}"

    user = User.new(:email => params['data'].try(:[], 'email'))
    user.first_name, user.last_name = user.email.split('@')
    user.send("#{::Devise.cas_username_column}=".to_sym, params['data'].try(:[], 'ido_id'))
    user.save
  end

  def user_removed
    puts "Removing user based on incoming data #{params.inspect}"
    puts "Devise username column: #{::Devise.cas_username_column}="

    ido_id = params['data'].try(:[], 'ido_id')

    ido_id and
      User.exists?(:conditions => {::Devise.cas_username_column => ido_id}) and
      User.where(::Devise.cas_username_column => ido_id).destroy
  end

  def user_updated
    puts "Updating user based on incoming data #{params.inspect}"
    puts "Devise username column: #{::Devise.cas_username_column}="
    ido_id = params['data'].try(:[], 'ido_id')

    if ido_id and User.exists?(:conditions => {::Devise.cas_username_column => ido_id}) 
      user = User.where(::Devise.cas_username_column => ido_id).first
      user.cloudfuji_extra_attributes(params['data'])
      user.save
    end
  end
end
