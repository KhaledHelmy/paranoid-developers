require 'openssl'
require 'base64'

class CodesController < ApplicationController
  before_action :set_code, only: [:show, :edit, :update, :destroy]

  # GET /codes
  # GET /codes.json
  def index
    @codes = Code.all
    @codes.each do |code|
      code.file_name = get_verified_decryption(code.id, code.file_name)
    end
  end

  # GET /codes/1
  # GET /codes/1.json
  def show
    @code.code = get_verified_decryption(@code.id, @code.code)
    @code.file_name = get_verified_decryption(@code.id, @code.file_name)
  end

  # GET /codes/new
  def new
    @code = Code.new
  end

  # GET /codes/1/edit
  def edit
    @code.code = get_verified_decryption(@code.id, @code.code)
    @code.file_name = get_verified_decryption(@code.id, @code.file_name)
  end

  # POST /codes
  # POST /codes.json
  def create
    code_param = code_params
    code_param[:user_id] = current_user.id

    cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
    cipher.encrypt
    key = cipher.random_key
    iv = cipher.random_iv
    cipher.key = key

    @code = Code.new(code_param)

    encrypted_code = cipher.update(@code.code)
    encrypted_code << cipher.final
    @code.code = Base64.encode64(encrypted_code)

    cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
    cipher.encrypt
    cipher.key = key
    cipher.iv = iv

    encrypted_file_name = cipher.update(@code.file_name)
    encrypted_file_name << cipher.final
    @code.file_name = Base64.encode64(encrypted_file_name)

    respond_to do |format|
      if @code.save
        public_key = OpenSSL::PKey::RSA.new(current_user.public_key)
        encrypted_key = Base64.encode64(public_key.public_encrypt(key))
        encrypted_iv = Base64.encode64(public_key.public_encrypt(iv))
        encryption = Encryption.new
        encryption.code_id = @code.id
        encryption.user_id = current_user.id
        encryption.encryption_key = encrypted_key
        encryption.encryption_iv = encrypted_iv
        encryption.save

        format.html { redirect_to @code, notice: 'Code was successfully created.' }
        format.json { render :show, status: :created, location: @code }
      else
        format.html { render :new }
        format.json { render json: @code.errors, status: :unprocessable_entity }
      end
    end
  end

  def access
    @users = User.where.not(id: current_user.id)
    if request.post?
      params[:user].each do |user_id, access|
        code_id = params[:id]
        if access == 1
          public_key = OpenSSL::PKey::RSA.new(User.find(user_id).public_key)
          symmetric_key = retrieve_symmetric_key(code_id)
          encrypted_key = Base64.encode64(public_key.public_encrypt(symmetric_key[:key]))
          encrypted_iv = Base64.encode64(public_key.public_encrypt(symmetric_key[:iv]))
          Encryption.where({code_id: code_id, user_id: user_id}).destroy_all
          encryption = Encryption.new
          encryption.code_id = code_id
          encryption.user_id = user_id
          encryption.encryption_key = encrypted_key
          encryption.encryption_iv = encrypted_iv
          encryption.save
        else
          Encryption.where({code_id: code_id, user_id: user_id}).destroy_all
        end
      end
     redirect_to codes_path
    end
  end

  # PATCH/PUT /codes/1
  # PATCH/PUT /codes/1.json
  def update
    respond_to do |format|
      code_param = code_params
      code_param[:user_id] = current_user.id

      symmetric_key = retrieve_symmetric_key(@code.id)
      key = symmetric_key[:key]

      cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
      cipher.encrypt
      iv = cipher.random_iv
      cipher.key = key

      encrypted_code = cipher.update(code_param[:code])
      encrypted_code << cipher.final
      code_param[:code] = Base64.encode64(encrypted_code)

      cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
      cipher.encrypt
      cipher.key = key
      cipher.iv = iv

      encrypted_file_name = cipher.update(code_param[:file_name])
      encrypted_file_name << cipher.final
      code_param[:file_name] = Base64.encode64(encrypted_file_name)

      if @code.update(code_param)
        users = Encryption.where(code_id: @code.id).pluck(:user_id)
        User.where(id: users).each do |user|
          public_key = OpenSSL::PKey::RSA.new(user.public_key)
          encrypted_iv = Base64.encode64(public_key.public_encrypt(iv))
          encryption = Encryption.find_by(code_id: @code.id, user_id: user.id)
          encryption.encryption_iv = encrypted_iv
          encryption.save
        end
        format.html { redirect_to @code, notice: 'Code was successfully updated.' }
        format.json { render :show, status: :ok, location: @code }
      else
        format.html { render :edit }
        format.json { render json: @code.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /codes/1
  # DELETE /codes/1.json
  def destroy
    @code.destroy
    respond_to do |format|
      format.html { redirect_to codes_url, notice: 'Code was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_code
      @code = Code.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def code_params
      params.require(:code).permit(:code, :file_name)
    end

    def get_verified_decryption(code_id, encrypted_text)
      original_text = encrypted_text
      begin
        decrypted_text = decrypt_method(code_id, encrypted_text)
      rescue Exception
        decrypted_text = original_text
      end
    end

    def decrypt_method(code_id, encrypted_text)
      symmetric_key = retrieve_symmetric_key(code_id)
      key = symmetric_key[:key]
      iv = symmetric_key[:iv]

      cipher = OpenSSL::Cipher.new('aes-256-cbc')
      cipher.decrypt
      cipher.key = key
      cipher.iv = iv

      decrypted_text = cipher.update(Base64.decode64(encrypted_text))
      decrypted_text << cipher.final
    end

    def retrieve_symmetric_key(code_id)
      encryption = Encryption.find_by(code_id: code_id, user_id: current_user.id)
      private_key = retrieve_private_key()
      symmetric_key = {}
      symmetric_key[:key] = private_key.private_decrypt(Base64.decode64(encryption.encryption_key))
      symmetric_key[:iv] = private_key.private_decrypt(Base64.decode64(encryption.encryption_iv))
      symmetric_key
    end

    def retrieve_private_key()
      private_key_file = `cat ~/.private_#{current_user.id}.pem`
      private_key = OpenSSL::PKey::RSA.new(private_key_file, session[:passphrase])
    end
end
