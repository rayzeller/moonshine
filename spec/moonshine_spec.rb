require "spec_helper"

describe Moonshine do

  describe "#add_items" do
    JAN_1 = Time.utc(2012, 1, 1, 8, 0)  
    JAN_2 = Time.utc(2012, 1, 2, 8, 0)  
    EVENTS = [JAN_1, JAN_2]
    DISTINCT_VALUES = ["xavier", "shinaynay"]
    let(:send_data) do
      {
        :type => 'order',
        :tags => ['real']
      }
    end

    before do
      for i in 0..EVENTS.length-1
        Moonshine.send(send_data.merge(:time => EVENTS[i], :data => {}, :summed => {:total => 500}, :distinct => {:ordered_from => DISTINCT_VALUES[i]}))
        Moonshine.send(send_data.merge(:time => EVENTS[1], :data => {}, :summed => {:total => 500}, :distinct => {:ordered_from => DISTINCT_VALUES[i]}))
      end
    end

    it "sums data correctly" do
      options = {:start => JAN_1, :step => 1.day, :type => 'order'}
      Moonshine.bootleg(options.merge(:metric => 'count', :key => 'total', :tags => ['real'])).should eq({"count" => 4})
    end

    it "returns all data correctly" do
      options = {:start => JAN_1, :type => 'order'}
      Moonshine.bootleg(options.merge(:metric => 'all', :tags => ['real'], :only => ['total'])).should eq(
        {"real" =>
          {
            JAN_1.to_datetime => { "count" => 1, "total" => 500 },
            JAN_2.to_datetime => { "count" => 3, "total" => 1500}

            }
          }
        )
    end

    it "returns filtered data correctly" do
      options = {:start => JAN_1, :type => 'order'}
      Moonshine.bootleg(options.merge(:metric => 'all', :tags => ['real'], :only => ['total'], :filter_key => 'ordered_from', :filter_value => 'xavier')).should eq(
        {"real" =>
          {
            JAN_1.to_datetime => { "count" => 1, "total" => 500 },
            JAN_2.to_datetime => { "count" => 1, "total" => 500}

            }
          }
        )
    end


  end
end