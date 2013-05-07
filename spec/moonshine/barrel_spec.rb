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
      send_data[:time].in_time_zone("Pacific Time (US & Canada)")
    end

    before do
      Moonshine.send(send_data)
    end

    it "Barrel contains 1 ordered_from_value" do
      expect(Moonshine::Barrel.where(:times => {
          :y => timestamp.beginning_of_year,
          :m => timestamp.beginning_of_month,
          :d => timestamp.beginning_of_day,
          :h => timestamp.beginning_of_hour},
          :e => send_data[:type],
          :t => timestamp,
          'd.ordered_from' => send_data[:data][:ordered_from].to_s).count).to eq(1)
    end

    it "Barrel contains 1 total value" do

    expect(Moonshine::Barrel.where(:times => {
          :y => timestamp.beginning_of_year,
          :m => timestamp.beginning_of_month,
          :d => timestamp.beginning_of_day,
          :h => timestamp.beginning_of_hour},
          :e => "order",
          :t => timestamp,
          'd.total' => send_data[:data][:total]).count).to eq(1)
    end

  end
end