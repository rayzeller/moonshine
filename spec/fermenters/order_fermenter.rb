class OrderFermenter < Moonshine::Fermenter

  type 'order'
  time :created_at

  data :user_id, :store_id, :swipe_fee, :cc_charge
  data_point :sales_tax, :key => :tax
  data_point :total
  data_point :subtotal

  tag :real, :if => lambda { |object| true }
  tag :fake, :if => lambda { |object| true }
  tag :dumb, :if => lambda { |object| true }
  tag :stupid, :if => lambda { |object| true }

  def swipe_fee
    object.calc_swipe 
  end

  def cc_charge
    object.calc_cc_charge
  end


end