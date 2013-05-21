require "spec_helper"

describe Moonshine::Barrel::Lifetime do

  describe "#add_item_to_barrel" do

    let(:send_data) do
      {
        :type => 'order',
        :time => Time.utc(2012, 1, 2, 8, 0),
        :data => {
          :ordered_from => "xavier", 
        },
        :summed => {
          :total => 500
        },
        :distinct => {
          :user_id => 5,
          :store_id => 510,
        },
        :tags => ['test']
      }
    end

    let(:timestamp) do
      send_data[:time].in_time_zone("Pacific Time (US & Canada)")
    end

    before do
      Moonshine.send(send_data)
    end 



    it "Barrel updates the counter" do
        type = send_data[:type]
        expect(Moonshine::Barrel::Lifetime.where('type' => type)
          .where({"fkey" => 'user_id', 'fval' => '5', "store_id.510._c" => 1}).count).to eq(1)
    end

    it "Barrel updates the sum" do
        type = send_data[:type]
        expect(Moonshine::Barrel::Lifetime.where('type' => type)
          .where({"fkey" => 'user_id', 'fval' => '5', "store_id.510.total" => 500}).count).to eq(1)
    end

    describe "#add_2nd_item_to_barrel" do
      before do
        Moonshine.send(send_data)
      end
      it "Barrel updates the counter" do
        type = send_data[:type]
        expect(Moonshine::Barrel::Lifetime.where('type' => type)
          .where({"fkey" => 'user_id', 'fval' => '5', "store_id.510._c" => 2}).count).to eq(1)
      end

      it "Barrel updates the sum" do
          type = send_data[:type]
          expect(Moonshine::Barrel::Lifetime.where('type' => type)
            .where({"fkey" => 'user_id', 'fval' => '5', "store_id.510.total" => 1000}).count).to eq(1)
      end

      describe "#recompute" do
        before do
          Moonshine::Barrel::Lifetime.recompute
        end

        it "Barrel recomputes in bulk" do
          type = send_data[:type]
          expect(Moonshine::Barrel::Lifetime.where('type' => type)
          .where({"fkey" => 'user_id', 'fval' => '5', "store_id.510._c" => 2}).count).to eq(1)
        end

        it "Barrel recomputes total in bulk" do
          type = send_data[:type]
          expect(Moonshine::Barrel::Lifetime.where('type' => type)
          .where({"fkey" => 'user_id', 'fval' => '5', "store_id.510.total" => 1000}).count).to eq(1)
        end
      end
    end

  end
end