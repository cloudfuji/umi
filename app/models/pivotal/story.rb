module Pivotal
  class Story
    include Mongoid::Document
    include Mongoid::Timestamps

    include Pivotal::Common

    belongs_to :project, :inverse_of => :stories, :class_name => "Pivotal::Project"
    has_many :notes, :class_name => "Pivotal::Note"

    field :url,                 :type => String
    field :created_at,          :type => DateTime
    field :accepted_at,         :type => DateTime
    field :external_project_id, :type => Integer
    field :name,                :type => String
    field :description,         :type => String
    field :story_type,          :type => String
    field :estimate,            :type => Integer
    field :current_state,       :type => String
    field :requested_by,        :type => String
    field :owned_by,            :type => String
    field :labels,              :type => String
    field :jira_id,             :type => Integer
    field :jira_url,            :type => Integer
    field :other_id,            :type => Integer
    field :integration_id,      :type => Integer
    field :deadline,            :type => DateTime
    field :attachments,         :type => Array
    field :external_id,         :type => Integer

    # Cloudfuji Fields
    field :ido_id,              :type => String
    field :announced,           :type => Boolean

    validates_uniqueness_of :external_id

    def self.find_by_external_id(id)
      self.first(:conditions => {:external_id => id})
    end

    def ido_schema_class
      "project_task"
    end

    def user
      self.project.user
    end

    # This could benefit from some regularization/metaprogramming
    def from_pivotal(foreign_story)
      self.url                 = foreign_story.url
      self.external_project_id = foreign_story.project_id
      self.name                = foreign_story.name
      self.description         = foreign_story.description
      self.story_type          = foreign_story.story_type
      self.estimate            = foreign_story.estimate
      self.current_state       = foreign_story.current_state
      self.requested_by        = User.find_by_full_name(foreign_story.requested_by).try(:ido_id) || foreign_story.requested_by
      self.owned_by            = User.find_by_full_name(foreign_story.owned_by).try(:ido_id)     || foreign_story.owned_by
      self.labels              = foreign_story.labels
      self.jira_id             = foreign_story.jira_id
      self.jira_url            = foreign_story.jira_url
      self.other_id            = foreign_story.other_id
      self.integration_id      = foreign_story.integration_id
      self.deadline            = foreign_story.deadline
      self.attachments         = foreign_story.attachments
      self.external_id         = foreign_story.id
    end

    def to_cloudfuji
      {
        :ido_id          => self.ido_id,
        :external_id     => self.external_id,
        :url             => self.url,
        :created_at      => self.created_at,
        :accepted_at     => self.accepted_at,
        :project_name    => self.project.name,
        :project_id      => self.project.ido_id,
        :title           => self.name,
        :description     => self.description,
        :task_type       => self.story_type,
        :estimate        => self.estimate,
        :state           => self.current_state,
        :requested_by_id => self.requested_by,
        :owned_by_id     => self.owned_by,
        :labels          => self.labels,
        :deadline        => self.deadline,
      }
    end
  end
end
