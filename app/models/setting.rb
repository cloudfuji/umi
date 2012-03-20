class Setting
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name,       :type => String
  field :human_name, :type => String
  field :settings,   :type => Hash

  validates_uniqueness_of :name

  def self.for(resource)
    self.first(:conditions => {:name => resource})
  end
end
