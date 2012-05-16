class AuthToken
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name,       :type => String
  field :human_name, :type => String
  field :token,      :type => Hash
  field :active,     :tyep => Boolean

  validates_uniqueness_of :name
  validates_uniqueness_of :token
  validates_uniqueness_of :human_name

  def self.for(resource)
    self.first(:conditions => {:name => resource})
  end

  def self.find_by_token(token)
    self.first(:conditions => {:active => true, :token => token})
  end

  def self.generate_token
    # From http://www.zacharyfox.com/blog/ruby-on-rails/password-hashing 
    (rand(128) + 64).times.collect { (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }.join
  end

  def self.create_new!(name, human_name)
    auth_token = self.new
    auth_token.token = self.generate_token
    auth_token.name = name
    auth_token.human_name = human_name
    auth_token.active = true

    if auth_token.save
      auth_token
    else
      false
    end
  end

  def disable!
    self.active = false
    self.save
  end
end
