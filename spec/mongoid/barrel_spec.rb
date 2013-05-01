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
        }
      }
    end

    let(:timestamp) do
      send_data[:time].in_time_zone("Pacific Time (US & Canada)").beginning_of_day
    end

    before do
      Moonshine.send(send_data)
    end

    it "Barrel contains 1 ordered_from_value" do
      expect(Moonshine::Barrel.where(:timestamp => timestamp.utc,
          :year => timestamp.beginning_of_year.strftime("%Y"),
          :month => timestamp.beginning_of_month.strftime("%m"),
          :day => timestamp.beginning_of_day.strftime("%d"),
          :type => "order_ordered_from",
          :value => send_data[:data][:ordered_from]).count).to eq(1)
    end

    it "Barrel contains 1 total value" do

      expect(Moonshine::Barrel.where(:timestamp => timestamp.utc,
          :year => timestamp.beginning_of_year.strftime("%Y"),
          :month => timestamp.beginning_of_month.strftime("%m"),
          :day => timestamp.beginning_of_day.strftime("%d"),
          :type => "order_total",
          :value => send_data[:data][:total]).count).to eq(1)
    end

  end
end