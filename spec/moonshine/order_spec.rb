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
        :calc_cc_charge => 23,
        :time => Time.new,
        :date => Time.zone.now.strftime("%a, %d %b %Y")
        )
    end

    let(:refund) do
      Refund.create(
        :order_id => order.id,
        :total => 500
        )
    end

    it "order gets sent to barrel" do
        tag = 'stupid'
        type = 'order'
        timestamp = order.created_at.in_time_zone("Pacific Time (US & Canada)")
        day_of_month = timestamp.day
        expect(Moonshine::Barrel::Monthly.where('tag' => tag)
          .where('time' => timestamp.beginning_of_month.utc)
          .where("day.#{day_of_month}._c" => 1).count).to eq(1)
    end

    it "summed attributes get summed" do
        tag = 'stupid'
        type = 'order'
        timestamp = order.created_at.in_time_zone("Pacific Time (US & Canada)")
        day_of_month = timestamp.day
        expect(Moonshine::Barrel::Monthly.where('tag' => tag)
          .where('time' => timestamp.beginning_of_month.utc)
          .where("day.#{day_of_month}.total" => 500).count).to eq(1)
    end

    it "distinct attributes get stuck in arrays" do
        tag = 'stupid'
        type = 'order'
        timestamp = order.created_at.in_time_zone("Pacific Time (US & Canada)")
        day_of_month = timestamp.day

        expect(Moonshine::Barrel::Monthly.where('tag' => tag)
          .where('time' => timestamp.beginning_of_month.utc)
          .where("day.#{day_of_month}.user_id" => [order.user_id]).count).to eq(1)
    end
  end
end