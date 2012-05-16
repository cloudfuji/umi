class AuthTokensController < ApplicationController
  before_filter :authenticate_request!

  def index
    respond_to do |format|
      format.json { render :json => AuthToken.all }
    end
  end

  def show
    respond_to do |format|
      if @auth_token = AuthToken.find(params[:id])
        format.json { render :json => @auth_token }
      else
        format.json { render :json => "not found", :status => 404 }
      end
    end
  end

  def create
    if @auth_token = AuthToken.create_new!(params[:name], params[:description])
      respond_to do |format|
        format.json { render :json => @auth_token }
      end
    else
      respond_to do |format|
        format.json { render :json => @auth_token.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @auth_token = AuthToken.find(params[:id])

    [:name, :description, :active].each do |key|
      @auth_token.send("#{key}=", params[:umi_token][key]) if !params[key].nil?
    end

    if @auth_token.save
      respond_to do |format|
        format.json { render :json => @auth_token }
      end
    else
      respond_to do |format|
        format.json { render :json => @auth_token.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @auth_token = AuthToken.find(params[:id])

    if @auth_token.destroy
      respond_to do |format|
        format.json { render :json => @auth_token }
      end
    else
      respond_to do |format|
        format.json { render :json => @auth_token.errors, :status => :unprocessable_entity }
      end
    end
  end
end

