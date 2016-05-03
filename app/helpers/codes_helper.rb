module CodesHelper
	def correct_passphrase()
		passphrase = session[:passphrase]
		begin
			private_key_file = `cat ~/.private_#{current_user.id}.pem`
			private_key = OpenSSL::PKey::RSA.new(private_key_file, passphrase)
			return true
		rescue Exception
			return false
		end
	end
end
