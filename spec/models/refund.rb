class Refund < ActiveRecord::Base
  include Moonshine::Observer
  include Moonshine::Checksum

  belongs_to :order
end