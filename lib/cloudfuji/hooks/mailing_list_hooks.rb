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
    # Find list in cached lists. If not present, refresh and try again
    list =  Mailchimp.find_list_or_refresh(data["mailing_list"].strip, user)
    raise "List '#{data["mailing_list"]}' could not be found on MailChimp account!" unless list

    # Find interest grouping
    grouping = Mailchimp.find_interest_grouping_or_refresh(list, data["mailing_list_grouping"].strip, user)

    if grouping
      # Create group if doesn't exist on grouping
      Mailchimp.find_or_create_interest_group_by_name grouping, data["mailing_list_group"].strip, user
    else
      # Create interest grouping (including group) if grouping doesn't exist
      puts "Interest Grouping '#{data["mailing_list_grouping"]}' not found. Creating with initial group '#{data["mailing_list_group"]}'..."
      grouping = Mailchimp.create_interest_grouping_for_list(list, data["mailing_list_grouping"], [data["mailing_list_group"]], user)
    end

    # Add group to email
    puts "Adding #{data["email"]} to group '#{data["mailing_list_group"]}' under grouping '#{data["mailing_list_grouping"]}'..."
    mc.listUpdateMember(
      :id => list.list_id,
      :email_address => data["email"],
      :merge_vars => {'GROUPINGS' => [ {'id' => grouping.grouping_id, 'groups' => data["mailing_list_group"]} ] },
      :email_type => "",
      :replace_interests => false
    )
  end
end
