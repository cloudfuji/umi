module Mailchimp
  class InterestGroup
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :interest_grouping, :inverse_of => :interest_groups, :class_name => "Mailchimp::InterestGrouping"

    field :name, :type => String

  end
end
