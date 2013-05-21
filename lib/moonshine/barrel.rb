require 'moonshine/barrel/monthly'
require 'moonshine/barrel/lifetime'

module Moonshine
  module Barrel
    extend ActiveSupport::Concern
    require 'deep_merge'
    # include Monthly

    # index({'time' => 1})
    # index({'monthly._id' => 1})

    #####
    #
    # Plans for Barrel
    #
    # # Unique value aggregator
    #
    # # Will aggregate values per day
    # # Unique users / day - per store or over all values
    # # Unique stores / day
    #
    # Maybe implement caching or a capped collection
    # 
    # Allow a way in fermenter for user to specify which values this can happen with
    #
    #####################
    def self.hooks(d = Distillery.new)
      ## make this faster ##

      Moonshine::Barrel::Monthly.log_hit(d)
      Moonshine::Barrel::Lifetime.log_hit(d)
    end

    def self.recompute
      Moonshine::Barrel::Monthly.recompute
      Moonshine::Barrel::Lifetime.recompute
    end
  end
end
