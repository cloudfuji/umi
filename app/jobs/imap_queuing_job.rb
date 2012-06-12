module IMAPQueuingJob
  @queue = :job_queuing

  class << self
    def perform(job_interval)
      # Find all IMAP accounts that haven't been processed for
      # at least {job_interval} minutes, and add them to the queue.

      IMAPAccount.any_of(
        {:last_processed_at.lt => job_interval.minutes.ago.utc},
        {:last_processed_at    => nil}
      ).each do |account|
        Resque.enqueue(IMAPJob, account.id)
      end
    end
  end
end
