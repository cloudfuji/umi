class AccountsController < ApplicationController
  before_filter :authenticate_user!

  def index
    @auth_token = AuthToken.find_by_name('ido_share')

    if @auth_token.nil?
      @auth_token = AuthToken.create_new!('ido_share', 'ido share starter')
    end

    @pivotal = Setting.first(:conditions => {:name => "pivotal"}).try(:settings) || {}
    @mailgun = Setting.first(:conditions => {:name => "mailgun"}).try(:settings) || {}
    @wufoo   = Setting.first(:conditions => {:name => "wufoo"  }).try(:settings) || {}
    @stripe  = Setting.first(:conditions => {:name => "stripe" }).try(:settings) || {}
  end

  def create
    config = Setting.find_or_create_by(:name => params[:name])
    config.settings = {:api_key => params[:api_key], :human_name => params[:name]}
    config.save

    flash[:notice] = "Ok, updated #{config.name}!"

    redirect_to root_url
  end
end
