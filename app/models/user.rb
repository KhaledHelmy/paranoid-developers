class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  has_many :codes
  has_many :encryptions
  has_many :encrypted_codes, through: :encryptions, source: :code, class_name: :Code, foreign_key: :user_id
end
