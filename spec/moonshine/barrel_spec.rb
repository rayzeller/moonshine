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

    it "Barrel updates the month counter" do
        tag = ''
        type = send_data[:type]
        id_monthly = "#{timestamp.strftime('%Y%m/')}#{type}/#{tag}"
        day_of_month = timestamp.day
        expect(Moonshine::Barrel.where('monthly._id' => id_monthly)
          .where('monthly.meta.time' => timestamp.beginning_of_month.utc)
          .where('monthly.meta.tag' => tag)
          .where('monthly.meta.type' => type)
          .where("monthly.daily.#{day_of_month}" => 1).count).to eq(1)
    end

     it "Barrel has updated the month counter for our tag" do
        tag = 'test'
        type = send_data[:type]
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