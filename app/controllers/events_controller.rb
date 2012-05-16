class EventsController < ApplicationController
  before_filter :umi_authenticate_token! # Just a placeholder for now

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
end
