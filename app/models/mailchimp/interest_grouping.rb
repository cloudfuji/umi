module Mailchimp
  class InterestGrouping
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :list, :inverse_of => :interest_groupings, :class_name => "Mailchimp::List"
    embeds_many :interest_groups, :inverse_of => :interest_grouping, :class_name => "Mailchimp::InterestGroup" do
      def find_by_name(name)
        where(:name => name).first
      end
    end

    field :grouping_id, :type => Integer
    field :name,        :type => String

  end
end
