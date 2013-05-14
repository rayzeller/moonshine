class Order < ActiveRecord::Base
  include Moonshine::Observer
  include Moonshine::Checksum

  has_many :refunds
end