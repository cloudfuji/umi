module Pivotal
  module Common
    def set_ido_id!
      self.ido_id ||= Bushido::Ido.retrieve_ido_id
    end
    
    def announce!
      klass    = self.class.name.split(":").last.downcase

      category = self.ido_schema_class
      name     = "created"
      data     = self.to_bushido

      human = {
        "project" => Proc.new { |project| "Project #{project.name} created from Pivotal Tracker" },
        "story"   => Proc.new { |story|   "#{story.story_type.titleize} task '#{story.name}' created from Pivotal: #{story.description} requested by #{User.first(:conditions => {:ido_id => story.requested_by}).full_name} due by #{story.deadline}" },
        "note"    => Proc.new { |note|    "Project task note created from Pivotal: #{note.text}" }
      }[klass].call(self)

      data[:human] = human

      Bushido::Event.publish(:category => category, :name => name, :data => data)
    end
  end
end
