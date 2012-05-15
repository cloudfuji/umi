module Pivotal
  class Project
    include Mongoid::Document
    include Mongoid::Timestamps

    include Pivotal::Common

    has_many :stories, :class_name => "Pivotal::Story"

    field :week_start_day,      :type => Integer
    field :initial_velocity,    :type => String
    field :name,                :type => String
    field :account,             :type => String
    field :week_start_day,      :type => String
    field :point_scale,         :type => String
    field :labels,              :type => String
    field :velocity_scheme,     :type => String
    field :iteration_length,    :type => Integer
    field :current_velocity,    :type => Integer
    field :last_activity_at,    :type => DateTime
    field :use_https,           :type => Boolean
    field :external_id,         :type => Integer

    # Cloudfuji Fields
    field :ido_id,         :type => String
    field :announced,      :type => Boolean

    validates_uniqueness_of :external_id

    def self.find_by_external_id(id)
      self.first(:conditions => {:external_id => id})
    end

    def ido_schema_class
      "project"
    end

    def from_pivotal(foreign_project)
      self.week_start_day   = foreign_project.week_start_day
      self.initial_velocity = foreign_project.initial_velocity
      self.name             = foreign_project.name
      self.account          = foreign_project.account
      self.week_start_day   = foreign_project.week_start_day
      self.point_scale      = foreign_project.point_scale
      self.labels           = foreign_project.labels
      self.velocity_scheme  = foreign_project.velocity_scheme
      self.iteration_length = foreign_project.iteration_length
      self.current_velocity = foreign_project.current_velocity
      self.last_activity_at = foreign_project.last_activity_at
      self.use_https        = foreign_project.use_https
      self.external_id      = foreign_project.id
    end

    def to_cloudfuji
      {
        :ido_id              => self.ido_id,
        :external_id         => self.external_id,
        :name                => self.name,
        :point_scale         => self.point_scale,
        :iteration_start_day => ["sunday","monday","tuesday","wednesday","thursday","friday","saturday"].index(self.week_start_day.downcase),
        :iteration_length    => self.iteration_length,
        :default_velocity    => self.initial_velocity,
        :human               => "Project #{self.name} imported from Pivotal Tracker"
      }
    end
  end
end
