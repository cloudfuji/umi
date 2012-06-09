require 'openssl'

class MailgunController < ApplicationController
  before_filter :umi_authenticate_token!
  before_filter :authenticate_request!


  def notification
    known_events = [:opened,       :clicked,    :delivered,
                    :unsubscribed, :complained,
                    :bounced,      :dropped]

    return render(:status => 400) unless known_events.include?(params["event"].to_sym)

    Cloudfuji::Event.publish(event)

    render :json => "ok", :status => 200
  end

  private

  def event
    data = self.send(params["event"].to_sym)

    event = {
      :category    => "email",
      :name        => params["event"],
      :data        => data,
      :user_ido_id => current_user.ido_id
    }
  end

  # http://documentation.mailgun.net/user_manual.html#tracking-opens
  def base
    {
      :event            => params["event"           ],
      :recipient        => params["recipient"       ],
      :domain           => params["domain"          ],
      :campaign_id      => params["campaign-id"     ],
      :campaign_name    => params["campaign-name"   ],
      :tag              => params["tag"             ],
      :mailing_list     => params["mailing-list"    ],
      :custom_variables => params["custom-variables"],
    }
  end

  def opened
    base
  end

  def clicked
    data = base
    data[:url]   = params["url"]
    data[:human] = "#{data[:recipient]} clicked on link in #{data[:campaign_name]} to #{data[:url]}"
    data
  end

  def complained
    data = base
    data[:message_headers] = params["message_headers"]
    data[:human] = "#{data[:recipient]} complained of spam in campaign #{data[:campaign_name]}"
    data
  end

  def bounced
    data = base
    data[:code]         = params["code"]
    data[:error]        = params["error"]
    data[:notification] = params["notification"]
    data[:human] = "Mail to #{data[:recipient]} bounced with: (#{data[:code]}) [#{data[:error]}] '#{data[:notification]}'"
    data
  end

  def dropped
    {
      :recipient        => params["recipient"       ],
      :message_headers  => params["message-headers" ],
      :reason           => params["reason"          ],
      :description      => params["description"     ],
      :custom_variables => params["custom-variables"],
      :human            => "Mail to #{params['recipient']} could not be delivered (#{params['reason']}) because #{params['description']}"
    }
  end

  def delivered
    {
      :recipient        => params["recipient"       ],
      :domain           => params["domain"          ],
      :message_headers  => params["message-headers" ],
      :message_id       => params["Message-Id"      ],
      :custom_variables => params["custom-variables"],
      :human            => "Mail to #{params['recipient']} successfully delievered."
    }
  end

  def unsubscribed
    {
      :recipient        => params["recipient"       ],
      :domain           => params["domain"          ],
      :tag              => params["tag"             ],
      :custom_variables => params["custom-variables"],
      :human            => "#{params['recipient']} unsubscribed from mailings in campaign #{params["campaign-name"]} from #{params["domain"]}."
    }
  end

  def verify
    token     = params["token"]
    timestamp = params["timestamp"]
    signature = params["signature"]
    digest    = OpenSSL::Digest::Digest.new('sha256')

    puts "Digest: #{digest}"
    puts "API Key: #{service_api_key}"
    puts "#{timestamp}#{token}"

    return signature == OpenSSL::HMAC.hexdigest(digest, service_api_key, "#{timestamp}#{token}")
  end

  def authenticate_request!
    return render(:layout => false, :json => "Mailgun token not verified", :status => 401) unless verify
  end

  def service_api_key
    current_user.settings_for("mailgun").settings['api_key']
  end
end
