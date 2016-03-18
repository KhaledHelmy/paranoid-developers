class RegistrationsController < Devise::RegistrationsController
  def new
    super
  end

  def create
    super
    if resource.save
      `openssl genrsa -out ~/.private_#{resource.id}.pem 2048`
      generated_public_key = `openssl rsa -in ~/.private_#{resource.id}.pem -outform PEM -pubout`
      resource.public_key = generated_public_key
      resource.save!
    end
  end

  def update
    super
  end
end 