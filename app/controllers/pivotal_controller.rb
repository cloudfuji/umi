class PivotalController < ApplicationController
  before_filter :umi_authenticate_token!, :except => [:import]

  # Note: Blocking, bad. Will need some refactoring.
  def import
    PivotalTrackerUtil.refresh_client!

    thread = Thread.new do
      PivotalTrackerUtil.import_initial!
    end

    flash[:notice] = "Importing your Pivotal Tracker data into Cloudfuji, it may take a bit!"
    thread.join
    redirect_to root_url
  end

  def received
    PivotalTrackerUtil.refresh_client!(current_user)

    known_events = [:story_create,
                    :story_update,
                    :story_delete,
                    :note_create]

    @event = params['activity']['event_type']
    find_foreign_project
    find_foreign_story

    if known_events.include?(@event.to_sym)
                           self.send(@event.to_sym, @foreign_story) if @event.starts_with("story")
      find_foreign_note && self.send(@event.to_sym, @foreign_note)  if @event.starts_with("note")
    end

    respond_to do |format|
      format.xml { render :xml => "ok", :status => 200 }
    end
  end

  private

  def story_create(foreign_story)
    @project = Pivotal::Project.find_by_external_id(@foreign_project.id)

    story = @project.stories.new
    story.from_pivotal(foreign_story)
    story.save
  end

  def story_update(foreign_story)
    story = Pivotal::Story.find_by_external_id(foreign_story.id)
    story.from_pivotal(foreign_story)
    story.save

    category     = "project_task"
    name         = "updated"
    data         = story.to_cloudfuji
    data[:human] = "In Pivotal, #{params['activity']['description']} on project #{story.project.name}"
    data[:url]   = params['activity']['stories'].first['url']

    event = {
      :category    => category,
      :name        => name,
      :user_ido_id => current_user.ido_id,
      :data        => data
    }

    Cloudfuji::Event.publish(event)
  end

  def story_delete(foreign_story)
    story = Pivotal::Story.find_by_external_id(foreign_story.id)

    category     = "project_task"
    name         = "deleted"
    data         = story.to_cloudfuji
    data[:human] = "In Pivotal, #{params['activity']['description']} on project #{story.project.name}"
    data[:url]   = url

    event = {
      :category    => category,
      :name        => name,
      :user_ido_id => current_user.ido_id,
      :data        => data
    }

    Cloudfuji::Event.publish(event)
  end

  def note_create(foreign_note)
    @story = Pivotal::Story.find_by_external_id(@foreign_story.id)
    @note = @story.notes.new
    @note.from_pivotal(foreign_note)
    @note.save
  end

  def find_foreign_project
    @foreign_project = PivotalTracker::Project.find(params['activity']['project_id']) unless params['activity']['project_id'].nil?
  end

  def find_foreign_story
    @foreign_story = @foreign_project.stories.find(params['activity']['stories'].first['id'])
  end

  def find_foreign_note
    @foreign_note = @foreign_story.notes.find(params['activity']['stories'].first['notes'].first['id'])
  end
end
