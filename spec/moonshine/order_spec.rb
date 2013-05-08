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
        tag = ''
        type = 'order'
        timestamp = order.created_at.in_time_zone("Pacific Time (US & Canada)")
        id_monthly = "#{timestamp.strftime('%Y%m/')}#{type}/#{tag}"
        day_of_month = timestamp.day
        expect(Moonshine::Barrel.where('monthly._id' => id_monthly)
          .where('monthly.meta.time' => timestamp.beginning_of_month.utc)
          .where('monthly.meta.tag' => tag)
          .where('monthly.meta.type' => type)
          .where("monthly.daily.#{day_of_month}" => 1).count).to eq(1)
    end
  end
end