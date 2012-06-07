class MailingListHooks < Cloudfuji::EventObserver

  # params = {'data' => {'email' => 'xxxxxx', 'mailing_list_grouping' => "Cloudfuji Pageviews", 'mailing_list_group' => 'A new Group'}}
  # settings = {'api_key' => 'xxxxxxxx', 'list' => 'Test List'}
  def mailing_list_group_added
    data = params["data"]

    # TODO - There's no way to figure out which user settings to use based on a received event... ??
    # Just making the Umi user's ido_id field temporarily part of the event rule form, for now.
    user = User.where(:ido_id => data["user_ido_id"]).first
    raise "User could not be found by ido id: #{data["user_ido_id"]}" unless user

    settings = user.settings_for("mailchimp")
    # 'flatten' Setting model into settings hash
    settings = settings ? settings.settings : {}
    # Initialize Mailchimp API
    mc = Mailchimp::API.new(settings["api_key"])
    # Fetch lists from Mailchimp
    lists = mc.lists
    # Find configured list (for id)
    list = lists['data'].detect {|l| l['name'].downcase == data["mailing_list"].strip.downcase }
    raise "List '#{data["mailing_list"]}' could not be found on MailChimp account!" unless list

    # Find interest grouping
    groupings = mc.listInterestGroupings(:id => list['id'])
    grouping = groupings.detect do |g|
      g["name"].downcase == data["mailing_list_grouping"].strip.downcase
    end
    if grouping
      # If grouping exists, find or create group if doesn't exist
      unless grouping['groups'].detect {|g| g["name"].downcase == data["mailing_list_group"].strip.downcase }
        puts "Group '#{data["mailing_list_group"]}' not found on interest grouping '#{data["mailing_list_grouping"]}'. Creating..."
        mc.listInterestGroupAdd(:id => list['id'], :group_name => data["mailing_list_group"], :grouping_id => grouping["id"])
      end
    else
      # Create interest grouping (including group) if grouping doesn't exist
      puts "Interest Grouping '#{data["mailing_list_grouping"]}' not found. Creating with initial group '#{data["mailing_list_group"]}'..."
      grouping = { 'id' => mc.listInterestGroupingAdd(
        :id     => list['id'],
        :name   => data["mailing_list_grouping"],
        :type   => "checkboxes",
        :groups => [ data["mailing_list_group"] ]
      )}
    end

    # Add group to email
    puts "Adding #{data["email"]} to group '#{data["mailing_list_group"]}' under grouping '#{data["mailing_list_grouping"]}'..."
    mc.listUpdateMember(
      :id => list['id'],
      :email_address => data["email"],
      :merge_vars => {'GROUPINGS' => [ {'id' => grouping["id"], 'groups' => data["mailing_list_group"]} ] },
      :email_type => "",
      :replace_interests => false
    )
  end

end
