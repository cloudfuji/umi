module Pivotal
  class Note
    include Mongoid::Document
    include Mongoid::Timestamps

    include Pivotal::Common

    belongs_to :story, :inverse_of => :notes, :class_name => "Pivotal::Story"

    field :text,                :type => String
    field :author,              :type => String
    field :noted_at,            :type => DateTime
    field :story_name,          :type => String
    field :external_project_id, :type => Integer
    field :external_story_id,   :type => Integer
    field :external_id,         :type => Integer

    # Cloudfuji Fields
    field :ido_id,         :type => String
    field :announced,      :type => Boolean

    validates_uniqueness_of :external_id

    def ido_schema_class
      "project_task_note"
    end

    def user
      self.story.project.user
    end

    def from_pivotal(foreign_note)
      self.text                = foreign_note.text
      self.author              = User.find_by_full_name(foreign_note.author).try(:ido_id) || foreign_note.author
      self.noted_at            = foreign_note.noted_at
      self.external_project_id = story.project.external_id
      self.external_story_id   = story.external_id
      self.external_id         = foreign_note.id
    end

    def to_cloudfuji
      {
        :ido_id      => self.ido_id,
        :external_id => self.external_id,
        :note        => self.text,
        :user_id     => self.author,
        :noted_at    => self.noted_at,
        :story_name  => self.story.name,
        :project_id  => self.story.project.ido_id,
        :story_id    => self.story.ido_id,
      }      
    end
  end
end
