require "spec_helper"

describe Moonshine::Checksum do
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

    it "checksum confirms that order is in distillery" do
      expect(Order.checksum(order.created_at)).to eq(true)
    end
  end
end