module Mailchimp
  class List
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :user, :inverse_of => :mailchimp_lists
    embeds_many :interest_groupings, :inverse_of => :list, :class_name => "Mailchimp::InterestGrouping" do
      def find_by_name(name)
        where(:name => name).first
      end
    end

    field :list_id, :type => String
    field :name,    :type => String

  end
end
