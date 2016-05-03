class SessionsController < Devise::SessionsController

  def new
    super
  end

  def create
    passphrase = params[:user][:passphrase]
    if passphrase.empty?
      respond_to do |format|
        format.html { redirect_to new_user_session_path, notice: 'Please enter passphrase!' }
      end
    else
        params[:user].delete :passphrase
        session[:passphrase] = passphrase
        super
    end
  end

end