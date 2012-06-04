class CloudfujiUserHooks < Cloudfuji::EventObserver
  def cloudfuji_user_added
    puts "Adding a new user with incoming data #{params.inspect}"
    puts "Devise username column: #{::Devise.cas_username_column}="
    puts "Setting username to: #{data['ido_id']}"

    user = User.first(:conditions => {:ido_id => data['ido_id']})
    user ||= User.new(:email => data['email'])
    user.first_name, user.last_name = user.email.split('@')
    user.first_name = data['first_name'] if data['first_name'].present?
    user.last_name  = data['last_name']  if data['last_name'].present?
    user.email      = data['email']
    user.ido_id     = data['ido_id']
    user.save

    ["pivotal", "mailgun", "wufoo", "stripe", "github"].each do |service_name|
      user.settings.find_or_create_by(:name => service_name)
    end
  end

  def cloudfuji_user_removed
    puts "Removing user based on incoming data #{params.inspect}"
    puts "Devise username column: #{::Devise.cas_username_column}="

    ido_id = data['ido_id']

    ido_id and
      User.exists?(:conditions => {::Devise.cas_username_column => ido_id}) and
      User.where(::Devise.cas_username_column => ido_id).destroy
  end

  def cloudfuji_user_updated
    puts "Updating user based on incoming data #{params.inspect}"
    puts "Devise username column: #{::Devise.cas_username_column}="
    ido_id = data['ido_id']

    if ido_id and User.exists?(:conditions => {::Devise.cas_username_column => ido_id}) 
      user = User.where(::Devise.cas_username_column => ido_id).first
      user.cloudfuji_extra_attributes(data)
      user.save
    end
  end
end
