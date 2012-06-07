class Setting
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user, :inverse_of => :settings
  has_one :auth_token

  field :name,       :type => String
  field :human_name, :type => String
  field :settings,   :type => Hash, :default => {}

  validates_uniqueness_of :name, :scope => :user_id

  def self.for(resource)
    self.first(:conditions => {:name => resource})
  end

  def webhook_url(host = "cloudfujiapp.com")
    paths = {
      "mailgun"   => "/mailgun/notification",
      "mailchimp" => "/mailchimp/notification",
      "jenkins"   => "/jenkins/notification",
      "stripe"    => "/stripe/received",
      "github"    => "/github/received",
      "pivotal"   => "/pivotal/received",
      "events"    => "/events",
      "ido_share" => "/ido_share"
    }

    path = paths[settings['human_name']]

    puts "path: #{path}"
    puts "auth_token: #{auth_token}"

    return nil unless path && auth_token

    "http://#{host}#{path}?umi_token=#{auth_token.token}"
  end
end
