class Order < ActiveRecord::Base
  include Moonshine::Observer
  include Moonshine::Checksum

end