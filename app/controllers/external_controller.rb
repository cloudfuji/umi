class ExternalController < ApplicationController
  caches_page :external

  def index
    
  end

  def show
    @service = Setting.first(:conditions => {:name => params[:id]}).try(:settings) || {}
    if @service != {}
      @service_name = params[:id]
      render :layout => 'external'
    else
      render :status => :not_found
    end
  end
  
  def proxy
    @proxy_path = params[:proxy_path]
    render :layout => false
  end


end
