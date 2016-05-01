class RegistrationsController < Devise::RegistrationsController
  def new
    super
  end

  def create
    passphrase = params[:user][:passphrase]
    params[:user].delete :passphrase
    session[:passphrase] = passphrase
    super
    if resource.save
      `openssl genrsa -des3 -passout pass:#{passphrase} -out ~/.private_#{resource.id}.pem 2048`
      generated_public_key = `openssl rsa -in ~/.private_#{resource.id}.pem -passin pass:#{passphrase} -outform PEM -pubout`
      resource.public_key = generated_public_key
      resource.save!
    end
  end

  def update
    super
  end
end 