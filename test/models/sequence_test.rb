require 'test_helper'

class SequenceTest < ActiveSupport::TestCase
  test 'validates presence' do
    refute Sequence.new.save
  end

  test 'validates uniqueness' do
    assert Sequence.new(xml: 'A').save
    refute Sequence.new(xml: 'A').save
  end
end
