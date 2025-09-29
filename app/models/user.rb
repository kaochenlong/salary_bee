class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :user_companies, dependent: :destroy
  has_many :companies, through: :user_companies

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  generates_token_for :password_reset, expires_in: 15.minutes

  def self.find_by_password_reset_token!(token)
    find_by_token_for!(:password_reset, token)
  end
end
