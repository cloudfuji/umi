class PivotalObserver < Mongoid::Observer
  observe Pivotal::Project, Pivotal::Story, Pivotal::Note

  def before_create(record)
    record.set_ido_id!
  end

  def after_create(record)
    record.announce!
  end
end
