require 'moonshine/barrel/monthly'

module Moonshine
  module Barrel
    extend ActiveSupport::Concern
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

      log_hit(d)
    end

    def self.log_hit(d)
      # Update monthly stats document

      ## add ability to switch around timezones
      ## only logging stats for one or zero tags
      tags = (d['tags'].nil? || d['tags'].empty?) ? ["_all"] : d['tags']
      time = d['time'].in_time_zone("Pacific Time (US & Canada)")
      type = d['type']
      upsert = {}
      for tag in tags
        upsert[tag] ||= {}
        upsert[tag].merge!(Moonshine::Barrel::Monthly.hooks(tag, time, d['data'], d['summed']))
      end
      for tag in tags
        m = Moonshine::Barrel::Monthly.find_or_create_by(:tag => tag, :time => time.beginning_of_month.utc, :type => type)
        Moonshine::Barrel::Monthly.collection.find({:_id => m.id}).upsert(upsert[tag])
      end
    end

    def self.recompute
      Distillery.where(:time.lte => Time.zone.now.utc).batch_size(10000) do |group|
        upsert = {}
        group.each do |d|
          bulk_log(d, upsert)
        end
        
      end
    end
  end
end
