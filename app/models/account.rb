class Account < ApplicationRecord
  before_create :generate_access_token

  validates :access_token,
    presence: true,
    uniqueness: true,
    length: { minimum: 32, maximum: 256 },
    unless: :new_record?

  validates :user,
    presence: true,
    uniqueness: true,
    format: {
      with: /\A[^@\s]+@[^@\s]+\Z/i,
      on: :create
    }

  class << self
    def verify(access_token)
      account = find_by_access_token! access_token
    ensure
      account&.increment! :access_count
    end
  end

  def generate_access_token
    begin
      write_attribute :access_token, SecureRandom.hex(16)
    end while Account.exists?(access_token: access_token)
  end
end
