class EventsController < ApplicationController
  before_filter :umi_authenticate_token!, :only => :create # Just a placeholder for now

  # POST /events
  # Incoming requests are expected to be authenticated with an API token
  # Requests MUST have a `category` and `name`chr
  def create
    respond_to do |format|
      if Ido::EventProcessor.process_and_fire!(JSON.parse(params[:event]))
        format.json { render :json => true, :status => 200}
      else
        format.json { render :json => false, :status => :unprocessable_entity }
      end
    end
  end


  def script
    @auth_token = AuthToken.find_by_name('ido_share')

    if @auth_token.nil?
      @auth_token = AuthToken.create_new!('ido_share', 'ido share starter')
    end


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
