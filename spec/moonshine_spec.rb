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
        Moonshine.send(send_data.merge(:time => EVENTS[i], :data => {:ordered_from => DISTINCT_VALUES[i]}, :summed => {:total => 500}))
        Moonshine.send(send_data.merge(:time => EVENTS[1], :data => {:ordered_from => DISTINCT_VALUES[i]}, :summed => {:total => 500}))
      end
    end

    # it "distinct should correctly do some stuff" do
    #   options = {:start => JAN_1, :step => 1.day, :type => 'order'}
    #   hash = Moonshine.get(options.merge(:metric => 'distinct', :key => 'ordered_from'))
    #   expect(hash[JAN_1]).to eq([DISTINCT_VALUES[0]])
    #   expect(hash[JAN_2]).to eq([DISTINCT_VALUES[1]])
    # end

    # it "distinct count should correctly do some stuff" do
    #   options = {:start => JAN_1, :step => 1.day, :type => 'order'}
    #   hash = Moonshine.get(options.merge(:metric => 'distinct.count', :key => 'ordered_from'))
    #   expect(hash[JAN_1]).to eq(1)
    #   expect(hash[JAN_2]).to eq(1)
    # end


    # it "sum should correctly do some stuff" do
    #   options = {:start => JAN_1, :step => 1.day, :type => 'order'}
    #   hash = Moonshine.get(options.merge(:metric => 'sum', :key => 'total'))
    #   expect(hash[JAN_1]).to eq( 500 )
    #   expect(hash[JAN_2]).to eq( 500 )
    # end

    it "sum should correctly do some stuff" do
      options = {:start => JAN_1, :step => 1.day, :type => 'order', :filters => {:ordered_from => "xavier"}}
      Moonshine.bootleg(options.merge(:metric => 'count', :key => 'total', :tags => ['real'])).should eq({"count" => 4})
    end


  end
end