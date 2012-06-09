class AccountsController < ApplicationController
  before_filter :authenticate_user!

  def index
    @auth_token = current_user.auth_tokens.where(:name => 'ido_share').first

    if @auth_token.nil?
      @auth_token = current_user.auth_tokens.create_new!(current_user, 'ido_share', 'IdoShare starter')
      puts "Auth token: #{@auth_token.inspect}"
      puts "errors: #{@auth_token.errors.inspect}"
    end

    %w(pivotal mailgun wufoo stripe github mailchimp gmail).each do |service|
      instance_variable_set("@#{service}", current_user.settings_for(service))
    end
  end

  def create
    config = current_user.settings.find_or_create_by(:name => params[:name])
    if %w(api_key password).any? { |f| params[f].present? }
      %w(api_key email password).each do |field|
        config.settings[field] = params[field] if params[field].present?
      end
      config.settings['human_name'] = params[:name]

      config.auth_token ||= current_user.auth_tokens.create!(:name => params[:name], :description => params[:name])
    else
      # Delete settings and auth token if api_key is blank
      config.settings = {}
      config.auth_token = nil
    end
    config.save

    puts "Config: #{config.inspect}"

    flash[:notice] = "Ok, updated #{config.name}!"
    puts "Config: #{config.inspect}"
    puts "Config: #{config.errors.inspect}"

    redirect_to root_url
  end
end
