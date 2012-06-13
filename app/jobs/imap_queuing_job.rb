module ImapQueuingJob
  @queue = :job_queuing

  class << self
    def perform(params={})
      # Find all IMAP accounts that haven't been processed for
      # at least {job_interval} minutes, and add them to the queue.

      job_interval = params['job_interval']

      IMAPAccount.any_of(
        {:last_processed_at.lt => job_interval.minutes.ago.utc},
        {:last_processed_at    => nil}
      ).each do |account|
        Resque.enqueue(ImapJob, account.id)
      end
    end
  end
end
