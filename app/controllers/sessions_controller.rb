class SessionsController < Devise::SessionsController

  def new
    super
  end

  def create
    passphrase = params[:user][:passphrase]
    params[:user].delete :passphrase
    session[:passphrase] = passphrase
    super
  end

end