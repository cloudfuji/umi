module Mailchimp
  class << self
    def refresh_lists_for(user)
      mc = mailchimp_api_for(user)
      # Clear all lists
      user.mailchimp_lists.each {|l| l.destroy }
      counts = Hash.new(0)
      # Fetch lists and groupings from Mailchimp, and store in db
      mc.lists['data'].each do |list_data|
        counts[:lists] += 1
        list = user.mailchimp_lists.create :list_id => list_data['id'], :name => list_data['name']
        refresh_groupings_for(list, user, counts)
      end
      return counts
    end

    def refresh_groupings_for(list, user, counts = Hash.new(0))
      mc = mailchimp_api_for(user)
      groupings = mc.listInterestGroupings(:id => list.list_id)
      unless groupings.is_a?(Hash) && groupings["error"]
        groupings.each do |grouping_data|
          counts[:groupings] += 1
          grouping = Mailchimp::InterestGrouping.new :grouping_id => grouping_data["id"].to_i, :name => grouping_data["name"]
          grouping_data['groups'].each do |group_data|
            counts[:groups] += 1
            grouping.interest_groups << Mailchimp::InterestGroup.new(:name => group_data["name"])
          end
          list.interest_groupings << grouping
        end
      end
    end

    def find_or_create_interest_group_by_name(grouping, group_name, user)
      mc = mailchimp_api_for(user)
      # Create group if doesn't exist
      unless grouping.interest_groups.detect {|g| g.name.downcase == group_name.downcase }
        puts "Group '#{group_name}' not found on interest grouping '#{grouping.name}'. Creating..."
        mc.listInterestGroupAdd :id => grouping.list.list_id, :group_name => group_name, :grouping_id => grouping.grouping_id
        grouping.interest_groups << Mailchimp::InterestGroup.new(:name => group_name)
      end
    end

    def create_interest_grouping_for_list(list, grouping_name, groups, user)
      mc = mailchimp_api_for(user)
      grouping_id = mc.listInterestGroupingAdd(
        :id     => list.list_id,
        :name   => grouping_name,
        :type   => "checkboxes",
        :groups => groups
      )
      grouping = Mailchimp::InterestGrouping.new :grouping_id => grouping_id, :name => grouping_name
      # Add groups to new Interest Grouping
      groups.each do |group|
        grouping.interest_groups << Mailchimp::InterestGroup.new(:name => group)
      end
      list.interest_groupings << grouping
      grouping
    end

    def mailchimp_api_for(user)
      Mailchimp::API.new(user.settings_for('mailchimp').settings["api_key"])
    end

    # Looks for list in cached lists, or refreshes lists once if:
    # - no cached lists
    # - cannot find list in cached lists
    def find_list_or_refresh(list_name, user)
      find_item_by_name_or_refresh(user, :mailchimp_lists, list_name) do
        puts "Could not find #{list_name} in cached lists, refreshing..."
        refresh_lists_for user
      end
    end

    # Looks for grouping in cached groupings, or refreshes list once if:
    # - no cached groupings
    # - cannot find grouping in cached groupings for list
    def find_interest_grouping_or_refresh(list, grouping_name, user)
      find_item_by_name_or_refresh(list, :interest_groupings, grouping_name) do
        puts "Could not find #{grouping_name} in cached list groupings, refreshing..."
        refresh_groupings_for list, user
      end
    end

    private

    # Shared 'find or refresh' method for Mailchimp lists & groupings
    def find_item_by_name_or_refresh(parent, collection_name, item_name, &block)
      refreshed, item = false, nil
      while !item && refreshed == false
        collection = parent.send(collection_name)
        if collection.none? || item == false
          yield   # Refresh collection from API in block
          refreshed = true
          collection = parent.send(collection_name)
        end
        item = collection.detect { |i| i.name.downcase == item_name.downcase } || false
        return item if item
      end
    end
  end
end
