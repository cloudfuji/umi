class AccountsController < ApplicationController
  before_filter :authenticate_user!

  def index
    @auth_token = current_user.auth_tokens.where(:name => 'ido_share').first

    if @auth_token.nil?
      @auth_token = current_user.auth_tokens.create_new!(current_user, 'ido_share', 'IdoShare starter')
      puts "Auth token: #{@auth_token.inspect}"
      puts "errors: #{@auth_token.errors.inspect}"
    end

    %w(pivotal mailgun wufoo stripe github mailchimp).each do |service|
      instance_variable_set("@#{service}", current_user.settings_for(service))
    end

    @imap_accounts = IMAPAccount.where(:user_id => current_user.id).all
  end

  def create
    config = current_user.settings.find_or_create_by(:name => params[:name])
    if params['api_key'].present? || params['imap'] && params['imap']['password'].present?

      config.settings = params[params[:name]] if params[params[:name]]

      config.settings['api_key'] = params['api_key'] if params['api_key'].present?
      config.settings['human_name'] = params[:human_name] || params[:name]
      # Set data hash from name, if present (ie.g. 'imap')


      config.auth_token ||= current_user.auth_tokens.create!(:name => params[:name], :description => params[:name])
    else
      # Delete settings and auth token if api_key is blank
      config.settings = {}
      config.auth_token = nil
    end
    config.save

    puts "Config: #{config.inspect}"

    flash[:notice] = "Ok, updated #{config.settings['human_name']}!"
    puts "Config: #{config.inspect}"
    puts "Config: #{config.errors.inspect}"

    redirect_to root_url
  end
end
