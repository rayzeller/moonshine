require "spec_helper"

describe Moonshine::Distillery do
  describe "#create order" do
    let(:order) do
      Order.create(:user_id  => "user",
        :store_id => "store",
        :total => 500,
        :subtotal => 450,
        :sales_tax => 50,
        :calc_swipe => 5,
        :calc_cc_charge => 23,
        :time => Time.new,
        :date => Time.zone.now.strftime("%a, %d %b %Y")
        )
    end

    it "serializes dates as a data point in the Distillery" do
      tag = 'stupid'
      type = 'order'
      timestamp = order.created_at.in_time_zone("Pacific Time (US & Canada)")
      day_of_month = timestamp.day
      expect(Moonshine::Distillery.where('type' => type)
        .where('time' => order.created_at)
        .where('data.date' => order.date).count).to eq(1)
    end
  end
end