class IMAPAccount
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user
  
  field :server,                    :type => String
  field :ssl,                       :type => String
  field :port,                      :type => Integer
  field :inbox_folder,              :type => String
  field :sent_mail_folder,          :type => String
  field :email,                     :type => String
  field :password,                  :type => String

  field :last_received_message_uid, :type => Integer
  field :last_sent_message_uid,     :type => Integer
  
  field :last_processed_at,         :type => DateTime
end
