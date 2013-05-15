require "spec_helper"

describe Moonshine::Barrel::Monthly do

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



    it "Barrel updates the month counter for our test tag" do
        tag = 'test'
        type = send_data[:type]
        day_of_month = Moonshine::Barrel::Monthly.two_digit_day(timestamp)
        expect(Moonshine::Barrel::Monthly.where('tag' => tag)
          .where('time' => timestamp.beginning_of_month.utc)
          .where("day.#{day_of_month}._c" => 1).count).to eq(1)
    end

    describe "#recompute" do
      before do
        Moonshine::Barrel.recompute
      end

      it "Barrel recomputes in bulk" do
        tag = 'test'
        type = send_data[:type]
        day_of_month = Moonshine::Barrel::Monthly.two_digit_day(timestamp)
        expect(Moonshine::Barrel::Monthly.where('tag' => tag)
          .where('time' => timestamp.beginning_of_month.utc)
          .where('type' => type)
          .where("day.#{day_of_month}._c" => 1).count).to eq(1)
      end
    end
  end
end