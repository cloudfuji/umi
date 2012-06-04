class User
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :auth_tokens
  has_many :settings
  has_many :pivotal_projects, :class_name => "Pivotal::Project"

  field :first_name
  field :last_name
  field :email
  field :locale
  field :ido_id,    :type    => String
  field :admin,     :type    => Boolean, :default => true  
  field :timezone,  :default => "UTC"
  field :authentication_token

  index :email
  index :ido_id
  index :authentication_token

  validates_presence_of   :ido_id
  validates_uniqueness_of :ido_id

  after_destroy :destroy_watchers
  before_save :ensure_authentication_token

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :ido_id, :first_name, :last_name

  devise :cloudfuji_authenticatable, :token_authenticatable

  def self.find_by_full_name(name)
    puts "Name: #{name}"
    User.first(:conditions => {:first_name => name.split(" ").first, :last_name => name.split(" ").last}) if name
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def cloudfuji_extra_attributes(extra_attributes)
    self.first_name = extra_attributes["first_name"].to_s
    self.last_name  = extra_attributes["last_name"].to_s
    self.email      = extra_attributes["email"]
    self.locale     = extra_attributes["locale"]
    self.timezone   = extra_attributes["timezone"]
  end

  def settings_for(service_name)
    settings.where(:name => service_name).first
  end
end
