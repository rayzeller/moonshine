require "spec_helper"

describe Moonshine::Barrel do

  describe "#add_item_to_barrel" do

    let(:send_data) do
      {
        id: 1,
        :type => 'order',
        :time => Time.now.utc,
        :data => {
          :ordered_from => "xavier", 
          :total => 500
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
        day_of_month = timestamp.day
        expect(Moonshine::Barrel::Monthly.where('tag' => tag)
          .where('time' => timestamp.beginning_of_month.utc)
          .where("day.#{day_of_month}._c" => 1).count).to eq(1)
    end

  end
end