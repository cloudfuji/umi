class AccountsController < ApplicationController
  before_filter :authenticate_user!

  def index
    @auth_token = current_user.auth_tokens.where(:name => 'ido_share').first

    if @auth_token.nil?
      @auth_token = current_user.auth_tokens.create_new!(current_user, 'ido_share', 'IdoShare starter')
      puts "Auth token: #{@auth_token.inspect}"
      puts "errors: #{@auth_token.errors.inspect}"
    end
    
    @pivotal = current_user.settings_for("pivotal")
    @mailgun = current_user.settings_for("mailgun")
    @wufoo   = current_user.settings_for("wufoo"  )
    @stripe  = current_user.settings_for("stripe" )
    @github  = current_user.settings_for("github" )
  end

  def create
    config = current_user.settings.find_or_create_by(:name => params[:name])
    config.settings ||= {}
    config.settings['api_key'] = params[:api_key]
    config.settings['human_name'] = params[:name]
    config.auth_token ||= current_user.auth_tokens.create!(:name => params[:name], :description => params[:name])
    config.save

    puts "Config: #{config.inspect}"

    flash[:notice] = "Ok, updated #{config.name}!"
    puts "Config: #{config.inspect}"
    puts "Config: #{config.errors.inspect}"

    redirect_to root_url
  end
end
