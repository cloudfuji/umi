module ImapJob
  @queue = :account_polling

  class << self
    def perform(imap_account_id)
      require 'net/imap'

      imap_account = IMAPAccount.where(:_id => imap_account_id).first
      raise "Could not find IMAP Account with id: #{imap_account_id}" unless imap_account

      # Update last_processed_at timestamp
      imap_account.update_attribute "last_processed_at", Time.now
      
      imap = connect(imap_account)
      
      [
        [imap_account.inbox_folder,     :received],
        [imap_account.sent_mail_folder, :sent]
      ].each do |folder, event_name|
        puts "Checking folder '#{folder}' for #{event_name} emails..."
        imap.select(folder)

        last_uid = imap_account.send("last_#{event_name}_message_uid")
        if last_uid.present?
          # Search for all mail with UID greater or equal to last email
          # Remove the last UID from results.
          email_uids = imap.uid_search("UID #{last_uid + 1}:*") - [last_uid]
        else
          # Get emails since IMAPAccount creation date
          puts "First run: Fetching emails since #{imap_account.created_at.to_s(:short)}"
          email_uids = imap.uid_search([
            "SINCE",
            Net::IMAP.format_date(imap_account.created_at)
          ]) 
        end
        
        puts "There are (#{email_uids.size}) new emails to fire as events..."
        email_uids.each do |uid|
          # Fetch email data, PEEK ensures that unseen messages are not marked as read.
          imap_data = imap.uid_fetch(uid, 'BODY.PEEK[]').first.attr
          email = Mail.new imap_data["BODY[]"]

          next if email.to.nil? || email.from.nil? # Why would email.to be nil?

          event = {
            :category => 'email',
            :name     => event_name,
            :data     => {
              :uid        => uid,
              :folder     => folder,
              :account    => imap_account.email,
              :to         => email.to.join(';'),
              :from       => email.from.join(';'),
              :cc         => email.cc,
              :date       => email.date,
              :subject    => email.subject,
              :rfc822     => imap_data["BODY[]"]
            }
          }

          puts "Publishing Cloudfuji Event: #{event.inspect}"
          ::Cloudfuji::Event.publish(event)
        end

        # Update last UID for account/folder if any emails were processed
        if email_uids.any?
          imap_account.update_attribute "last_#{event_name}_message_uid", email_uids.last
        end
      end

      disconnect(imap)
    end

    private

    def connect(imap_account)
      puts "Connecting & logging in to #{imap_account.server}..."
      imap = Net::IMAP.new(imap_account.server, imap_account.port, imap_account.ssl)
      imap.login(imap_account.email, imap_account.password)
      puts "Logged in to #{imap_account.server}."
      imap
    end

    def disconnect(imap)
      if imap
        imap.logout
        unless imap.disconnected?
          imap.disconnect rescue nil
        end
      end
    end

  end
end
