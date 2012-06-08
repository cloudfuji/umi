class MailchimpController < ApplicationController
  before_filter :umi_authenticate_token!, :except => [:refresh_lists]

  def notification
    known_event_types = [:subscribe,
                         :unsubscribe,
                         :profile,
                         :upemail, #(update email)
                         :cleaned,
                         :campaign]

    return render(:status => 400) unless known_event_types.include?(params["type"].to_sym)

    Cloudfuji::Event.publish(event)

    render :json => "ok", :status => 200
  end

  # For when Mailchimp is testing that our webhook works
  def confirm_webhook
    render :json => "ok", :status => 200
  end

  # Fetch and store Mailchimp Lists, Groupings and Groups
  def refresh_lists
    settings = current_user.settings_for("mailchimp")
    unless settings && settings.settings["api_key"]
      flash[:warning] = "You need to configure your Mailchimp API key!"
      redirect_to(root_url) and return
    end
    counts = Mailchimp.refresh_lists_for(current_user)

    flash[:notice] = "Successfully cached #{pluralize counts[:lists], 'list'}, #{pluralize counts[:groupings], 'grouping'}, and #{pluralize counts[:groups], 'group'}."
    redirect_to(root_url)
  end

  private

  class TextHelper
    include Singleton; include ActionView::Helpers::TextHelper
  end
  def pluralize(*args)
    TextHelper.instance.pluralize(*args)
  end

  def event
    # Conform event categories and names
    event_category, event_type = case params["type"].to_sym
    when :subscribe;   [:customer, :mailchimp_subscribed]
    when :unsubscribe; [:customer, :mailchimp_unsubscribed]
    when :profile;     [:customer, :mailchimp_profile_updated]
    when :upemail;     [:customer, :mailchimp_email_updated]
    when :campaign;    [:campaign, :status]
    else [:email, params["type"].to_sym]
    end

    event_data = self.send("#{event_category}_#{event_type}".to_sym)
    {
      :category    => event_category,
      :name        => event_type,
      :data        => event_data,
      :user_ido_id => current_user.ido_id
    }
  end

  def data
    params['data']
  end

  # "type": "subscribe",
  # "fired_at": "2009-03-26 21:35:57",
  # "data[id]": "8a25ff1d98",
  # "data[list_id]": "a6b5da1054",
  # "data[email]": "api@mailchimp.com",
  # "data[email_type]": "html",
  # "data[merges][EMAIL]": "api@mailchimp.com",
  # "data[merges][FNAME]": "MailChimp",
  # "data[merges][LNAME]": "API",
  # "data[merges][INTERESTS]": "Group1,Group2",
  # "data[ip_opt]": "10.20.10.30",
  # "data[ip_signup]": "10.20.10.30"
  def customer_mailchimp_subscribed
    {
      :list_id          => data['list_id'],
      :fired_at         => params['fired_at'],
      :mailchimp_id     => data['id'],
      :email            => data['email'],
      :email_type       => data['email_type'],
      :merges           => data['merges'],
      :ip_opt           => params['ip_opt'],
      :ip_signup        => params['ip_signup'],
      :human            => "#{data[:email]} subscribed to Mailchimp list with ID #{data['list_id']}"
    }
  end

  # "type": "unsubscribe",
  # "fired_at": "2009-03-26 21:40:57",
  # "data[action]": "unsub",
  # "data[reason]": "manual",
  # "data[id]": "8a25ff1d98",
  # "data[list_id]": "a6b5da1054",
  # "data[email]": "api+unsub@mailchimp.com",
  # "data[email_type]": "html",
  # "data[merges][EMAIL]": "api+unsub@mailchimp.com",
  # "data[merges][FNAME]": "MailChimp",
  # "data[merges][LNAME]": "API",
  # "data[merges][INTERESTS]": "Group1,Group2",
  # "data[ip_opt]": "10.20.10.30",
  # "data[campaign_id]": "cb398d21d2",
  # "data[reason]": "hard"
  def customer_mailchimp_unsubscribed
    {
      :list_id          => data['list_id'],
      :fired_at         => params['fired_at'],
      :mailchimp_id     => data['id'],
      :email            => data['email'],
      :email_type       => data['email_type'],
      :merges           => data['merges'],
      :ip_opt           => params['ip_opt'],
      :campaign_id      => data['campaign_id'],
      :human            => "#{data[:email]} unsubscribed from Mailchimp list with ID #{data['list_id']}"
    }
  end

  # "type": "profile",
  # "fired_at": "2009-03-26 21:31:21",
  # "data[id]": "8a25ff1d98",
  # "data[list_id]": "a6b5da1054",
  # "data[email]": "api@mailchimp.com",
  # "data[email_type]": "html",
  # "data[merges][EMAIL]": "api@mailchimp.com",
  # "data[merges][FNAME]": "MailChimp",
  # "data[merges][LNAME]": "API",
  # "data[merges][INTERESTS]": "Group1,Group2",
  # "data[ip_opt]": "10.20.10.30"
  def customer_mailchimp_profile_updated
    {
      :list_id          => data['list_id'],
      :fired_at         => params['fired_at'],
      :mailchimp_id     => data['id'],
      :email            => data['email'],
      :email_type       => data['email_type'],
      :merges           => data['merges'],
      :ip_opt           => params['ip_opt'],
      :human            => "#{data[:email]} updated Mailchimp profile information."
    }
  end

  # "type": "upemail",
  # "fired_at": "2009-03-26\ 22:15:09",
  # "data[list_id]": "a6b5da1054",
  # "data[new_id]": "51da8c3259",
  # "data[new_email]": "api+new@mailchimp.com",
  # "data[old_email]": "api+old@mailchimp.com"
  def customer_mailchimp_email_updated
    {
      :list_id          => data['list_id'],
      :fired_at         => params['fired_at'],
      :new_mailchimp_id => data['id'],
      :new_email        => data['new_email'],
      :old_email        => data['old_email'],
      :human            => "#{data[:email]} updated their email address on Mailchimp, from '#{data['old_email']}' to '#{data['new_email']}'."
    }
  end

  # "type": "cleaned",
  # "fired_at": "2009-03-26 22:01:00",
  # "data[list_id]": "a6b5da1054",
  # "data[campaign_id]": "4fjk2ma9xd",
  # "data[reason]": "hard",
  # "data[email]": "api+cleaned@mailchimp.com"
  def email_cleaned
    {
      :list_id          => data['list_id'],
      :fired_at         => params['fired_at'],
      :campaign_id      => data['campaign_id'],
      :email            => data['email'],
      :reason           => data['reason'],
      :human            => "#{data[:email]} was cleaned from Mailchimp list with ID #{data['list_id']}. Reason: '#{data['reason']}'"
    }
  end

  # "type": "campaign",
  # "fired_at": "2009-03-26 21:31:21",
  # "data[id]": "5aa2102003",
  # "data[subject]": "Test Campaign Subject",
  # "data[status]": "sent",
  # "data[reason]": "",
  # "data[list_id]": "a6b5da1054"
  def campaign_status
    {
      :list_id          => data['list_id'],
      :campaign_id      => data['id'],
      :subject          => data['subject'],
      :status           => data['status'],
      :reason           => data['reason'],
      :human            => "Campaign Status (ID: #{data['id']}) - Subject: '#{data['subject']}', Status: '#{data['status']}', Reason: '#{data['reason']}'"
    }
  end

end
