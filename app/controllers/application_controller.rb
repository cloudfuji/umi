class ApplicationController < ActionController::Base
  protect_from_forgery

  def umi_authenticate_token!
    if (@umi_token = AuthToken.find_by_token(params[:umi_token])).nil?
      respond_to do |format|
        format.html { render :json => "Unauthorized", :status => :unauthorized }
        format.json { render :json => "Unauthorized", :status => :unauthorized }
      end

      return false
    end

    current_user = @umi_token.user
    @current_user = @umi_token.user
    self.instance_variable_set("@current_user", @umi_token.user)
  end
end
