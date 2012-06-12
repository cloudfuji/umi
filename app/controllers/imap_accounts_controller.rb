class IMAPAccountsController < ApplicationController
  before_filter :authenticate_user!

  def create
    @imap = IMAPAccount.create params[:imap].merge(:user_id => current_user.id)
    if @imap.errors.any?
      flash[:warning] = "Sorry, your IMAP account had errors!"
    else
      flash[:notice]  = "Ok, created IMAP account!"
    end
    redirect_to root_url
  end

  def destroy
    if @imap = IMAPAccount.where(:_id => params[:id]).first
      @imap.destroy
      flash[:notice] = "Ok, deleted IMAP account."
    else
      flash[:warning] = "Could not find IMAP account!"
    end
    redirect_to root_url
  end
end
