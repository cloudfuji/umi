class EventsController < ApplicationController
  before_filter :umi_authenticate_token!, :only => :create # Just a placeholder for now

  # POST /events
  # Incoming requests are expected to be authenticated with an API token
  # Requests MUST have a `category` and `name`chr
  def create
    respond_to do |format|
      if Ido::EventProcessor.process_and_fire!(params[:event])
        format.json { render :json => true }
      else
        format.json { render :json => false, :status => :unprocessable_entity }
      end
    end
  end


  def script
    response.headers["Last-Modified"] = Time.now.httpdate.to_s
    response.headers["Expires"] = 0.to_s
    # HTTP 1.0
    response.headers["Pragma"] = "no-cache"
    # HTTP 1.1 'pre-check=0, post-check=0' (IE specific)
    response.headers["Cache-Control"] = 'no-store, no-cache, must-revalidate, max-age=0, pre-check=0, post-check=0'
    response.headers['Content-type'] = 'application/javascript; charset=utf-8'
    
    render :action => 'script', :layout => false, :content_type => 'text/javascript'
  end
end
