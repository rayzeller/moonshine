module Moonshine
  class Barrel
    include Mongoid::Document

    index({'monthly.meta.time' => 1, 'monthly.meta.type' => 1, 'monthly.meta.tag' => 1})
    index({'monthly._id' => 1})

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
      tags = d['tags'].nil? ? [] : d['tags']
      time = d['time'].in_time_zone("Pacific Time (US & Canada)")
      for tag in tags
        monthly_log(time, d.type, tag)
      end
      monthly_log(time, d.type, "")

    end

    def self.recompute
      Distillery.where(:time.lte => Time.zone.now.utc).each do |d|
        hooks(d)
      end
    end

    private
      def self.monthly_log(time, type, tag)
        id_monthly = "#{time.strftime('%Y%m/')}#{type}/#{tag}"
        day_of_month = time.day
        # b =  Barrel.collection.upsert('$set' => {'monthly.meta' => {'time' => time.beginning_of_month.utc, 'type' => type, 'tag' => tag) if b.nil?
        b =  Moonshine::Barrel.find_or_create_by(:type => 'order', :tag => tag)

        Moonshine::Barrel.collection.find({'_id' => b._id}).upsert('$inc' => {
         "monthly.daily.#{day_of_month}" => 1}, '$set' => {'monthly._id' => id_monthly, 'monthly.meta' => {'time' => time.beginning_of_month.utc, 'type' => type, 'tag' => tag}})
        
      end
  end
end
