require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  test 'user and access_token are mandatory' do
    refute Account.new.valid?

    assert Account.new(user: 'test@example.com').valid?
    assert Account.new(user: 'test@example.com',
                       access_token: SecureRandom.hex(16)).valid?

    a = Account.create(user: 'test@example.com')
    a.access_token = nil
    refute a.valid?
  end

  test 'access_token is created automatically' do
    refute Account.create!(user: 'test@example.com').access_token.blank?
  end

  test 'verify returns account for valid tokens' do
    assert Account.verify accounts(:sylvester).access_token
  end

  test 'raises record not found for invalid tokens' do
    assert_raises ActiveRecord::RecordNotFound do
      Account.verify 'BADC0DE'
    end
  end

  test 'verify increments access count' do
    a = accounts(:sylvester)

    Account.verify a.access_token

    refute_equal 1, a.access_count
    a.reload
    assert_equal 1, a.access_count

    Account.verify a.access_token

    a.reload
    assert_equal 2, a.access_count
  end
end
