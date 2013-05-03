require "spec_helper"

describe Order do
  describe "#create order" do

    let(:order) do
      Order.create(:user_id  => "user",
        :store_id => "store",
        :total => 500,
        :subtotal => 450,
        :sales_tax => 50,
        :calc_swipe => 5,
        :calc_cc_charge => 23
        )
    end

    it "order gets sent to barrel" do
      timestamp = order.created_at.in_time_zone("Pacific Time (US & Canada)").beginning_of_day
      expect(Moonshine::Barrel.where(
          :year => timestamp.beginning_of_year.strftime("%Y"),
          :month => timestamp.beginning_of_month.strftime("%m"),
          :day => timestamp.beginning_of_day.strftime("%d"),
          :type => "order_swipe_fee",
          :value => 5).count).to eq(1)
    end
  end
end