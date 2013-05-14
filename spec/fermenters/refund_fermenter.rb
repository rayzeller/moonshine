class RefundFermenter < Moonshine::Fermenter

  type 'refund'
  time :created_at

  data_point :order_id, :distinct => true
  data_point :total, :summed => true

end