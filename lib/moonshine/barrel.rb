require 'moonshine/barrel/monthly'

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
        upsert[tag].deep_merge!(Moonshine::Barrel::Monthly.hooks(tag, time, d['data'], d['summed']))
      end
      for tag in tags
        Moonshine::Barrel::Monthly.collection.find({:tag => tag, :time => time.beginning_of_month.utc, :type => type}).upsert(upsert[tag])
      end
    end

    def self.recompute
      Moonshine::Barrel::Monthly.delete_all
      upsert = {}
      c = 0
      Moonshine::Distillery.where(:time.lte => Time.zone.now.utc).each do |d|
        upsert.deep_merge!(Moonshine::Barrel::Monthly.bulk_log(d, upsert.dup))
        c = c + 1
        if(c > 10000)
          Moonshine::Barrel::Monthly.bulk_insert(upsert)
          upsert = {}
        end
      end
      Moonshine::Barrel::Monthly.bulk_insert(upsert)
    end
  end
end
