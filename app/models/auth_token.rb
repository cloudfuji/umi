class AuthToken
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user,    :inverse_of => :auth_tokens
  belongs_to :setting, :inverse_of => :auth_tokens

  field :name,        :type => String
  field :description, :type => String
  field :token,       :type => String
  field :active,      :type => Boolean

  validates_presence_of :name
  validates_presence_of :description
  validates_presence_of :token

  validates_uniqueness_of :name,        :scope => :user_id 
  validates_uniqueness_of :token,       :scope => :user_id
  validates_uniqueness_of :description, :scope => :user_id

  before_validation Proc.new { |auth_token| auth_token.token ||= AuthToken.generate_token }
  before_create Proc.new { |auth_token| auth_token.active = true }

  def self.for(resource)
    self.first(:conditions => {:name => resource})
  end

  def self.find_by_token(token)
    self.first(:conditions => {:active => true, :token => token})
  end

  def self.find_by_name(name)
    self.first(:conditions => {:active => true, :name => name})
  end

  def self.generate_token
    # From http://www.zacharyfox.com/blog/ruby-on-rails/password-hashing 
    (rand(16) + 64).times.collect { (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }.join
  end

  def self.create_new!(user, name, description)
    auth_token = self.new
    auth_token.user = user
    auth_token.token = self.generate_token
    auth_token.name = name
    auth_token.description = description
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
