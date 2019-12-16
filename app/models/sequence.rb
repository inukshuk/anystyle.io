class Sequence < ApplicationRecord
  validates :xml, presence: true, uniqueness: true
end
