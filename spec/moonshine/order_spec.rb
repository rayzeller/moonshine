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
      timestamp = order.created_at.in_time_zone("Pacific Time (US & Canada)")
      expect(Moonshine::Barrel.where(:times => {
          :y => timestamp.beginning_of_year,
          :m => timestamp.beginning_of_month,
          :d => timestamp.beginning_of_day,
          :h => timestamp.beginning_of_hour,
        },
        :t => timestamp,
        :e => "order",
        'd.swipe_fee' => 5).count).to eq(1)
    end
  end
end