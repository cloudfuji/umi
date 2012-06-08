class ExternalController < ApplicationController
  caches_page :external

  def index

  end

  def show

  end
  
  def proxy
    @proxy_path = params[:proxy_path]
    render :layout => false
  end


end
