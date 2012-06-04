class PivotalTrackerUtil
  class << self

    def refresh_client!(user)
      # Thread-safe-what?? :(
      PivotalTracker::Client.token = user.settings_for('pivotal').settings['api_key']
    end

    def projects(user)
      refresh_client!(user)

      PivotalTracker::Project
    end

    def import_initial!(user)
      refresh_client!(user)

      projects(user).all.each do |project|
        if create_cloudfuji_project(user, project)

          project.stories.all.each do |story|
            if create_cloudfuji_story(project, story)

              story.notes.all.each do |note|
                create_cloudfuji_note(project, story, note)
              end
            end
          end
        end
      end
    end

    def create_cloudfuji_project(user, foreign_project)
      project    = Pivotal::Project.find_or_initialize_by(:external_id => foreign_project.id)
      new_record = project.new_record?
      project.from_pivotal(foreign_project)
      project.user = user

      puts project.inspect
      result = project.save
      puts "PROJECT SAVED? #{result}"
      puts project.errors.inspect
      project.announce! if result && new_record
      result
    end

    def create_cloudfuji_story(foreign_project, foreign_story)
      project    = Pivotal::Project.find_or_initialize_by(:external_id => foreign_project.id)
      story      = project.stories.find_or_initialize_by(:external_id => foreign_story.id)
      new_record = story.new_record?
      story.from_pivotal(foreign_story)

      puts story.inspect
      result = story.save
      puts "STORY SAVED? #{result}"
      puts story.errors.inspect
      story.announce! if result && new_record
      result
    end

    def create_cloudfuji_note(foreign_project, foreign_story, foreign_note)
      project    = Pivotal::Project.find_or_initialize_by(:external_id => foreign_project.id)
      story      = project.stories.find_or_initialize_by(:external_id => foreign_story.id)
      note       = story.notes.find_or_initialize_by(:external_id => foreign_note.id)
      new_record = note.new_record?
      note.from_pivotal(foreign_note)
      

      puts note.inspect
      result = note.save
      puts "NOTE SAVED? #{result}"
      puts note.errors.inspect
      note.announce! if result && new_record
      result
    end
  end
end
