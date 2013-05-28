module Moonshine
  module Barrel
    class Monthly
      include Mongoid::Document

      field :time, :type => DateTime
      field :type, :type => String
      field :tag, :type => String
      field :fkey, :type => String
      field :fval, :type => String
      field :day, type: Hash

      def self.hooks(tag, time, distinct_attributes, summed_attributes)
        day_number = two_digit_day(time)
        add_to_set = {}
        inc = {"day.#{day_number}._c" => 1}
        distinct_attributes.each do |a, val|
          add_to_set["day.#{day_number}.#{a}"] = val
        end
        summed_attributes.each do |a, val|
          inc["day.#{day_number}.#{a}"] = val
        end
        atomic = {"$inc" => inc}
        atomic.merge!({"$addToSet" => add_to_set}) if !add_to_set.empty?
        atomic
      end

      def self.bulk_insert(upsert)
        upsert.each do |tag, times|
          times.each do |time, types|
            types.each do |type, u|
              Moonshine::Barrel::Monthly.collection.find({:tag => tag, :time => time, :type => type, :fkey => "", :fval => ""}).upsert(u)
            end
          end
        end
      end

      def self.bulk_insert_kv(upsert)
        upsert.each do |key, values|
          values.each do |value, tags|
            tags.each do |tag, times|
              times.each do |time, types|
                types.each do |type, u|
                  Moonshine::Barrel::Monthly.collection.find({:tag => tag, :time => time, :type => type, :fkey => key, :fval => value.to_s}).upsert(u)
                end
              end
            end
          end
        end
      end

      def self.log_hit(d, filter=false)
        # Update monthly stats document

        ## add ability to switch around timezones
        ## only logging stats for one or zero tags
        tags = (d['tags'].nil? || d['tags'].empty?) ? ["_all"] : d['tags']
        time = d['time'].in_time_zone("Pacific Time (US & Canada)")
        type = d['type']
        upsert = {}
        for tag in tags
          upsert[tag] ||= {}
          upsert[tag] = upsert[tag].deep_merge(Moonshine::Barrel::Monthly.hooks(tag, time, d['distinct'], d['summed']))
        end
        for tag in tags
          d['distinct'].each do |k, v|
            Moonshine::Barrel::Monthly.collection.find({:tag => tag, :time => time.beginning_of_month.utc, :type => type, :fkey => k, :fval => v.to_s}).upsert(upsert[tag])
          end
          Moonshine::Barrel::Monthly.collection.find({:tag => tag, :time => time.beginning_of_month.utc, :type => type, :fkey => '', :fval => ''}).upsert(upsert[tag])
        end
      end

      def self.bulk_log(d, upsert, filter = false)
        tags = (d['tags'].nil? || d['tags'].empty?) ? ["_all"] : d['tags']
        time = d['time'].in_time_zone("Pacific Time (US & Canada)")
        bom = time.beginning_of_month.utc
        type = d['type']
        d['summed'] =  d['summed'].nil? ? Hash.new : d['summed']
        d['distinct'] =  d['distinct'].nil? ? Hash.new : d['distinct']
        day_number = two_digit_day(time)

        for tag in tags
          upsert[tag] ||={}
          upsert[tag][bom] ||= {}
          upsert[tag][bom][type] ||= {}
          upsert[tag][bom][type]["$inc"] ||= Hash.new
          upsert[tag][bom][type]["$inc"]["day.#{day_number}._c"] ||=0
          upsert[tag][bom][type]["$inc"]["day.#{day_number}._c"] = upsert[tag][bom][type]["$inc"]["day.#{day_number}._c"] + 1
          if(!filter)
            d['distinct'].each do |k, val|
              upsert[tag][bom][type]["$addToSet"] ||= Hash.new
              upsert[tag][bom][type]["$addToSet"]["day.#{day_number}.#{k}"] ||= Hash.new
              upsert[tag][bom][type]["$addToSet"]["day.#{day_number}.#{k}"]["$each"] ||= []
              upsert[tag][bom][type]["$addToSet"]["day.#{day_number}.#{k}"]["$each"].push(val) if !upsert[tag][bom][type]["$addToSet"]["day.#{day_number}.#{k}"].include?(val)
            end
          end
          d['summed'].each do |k, val|
            upsert[tag][bom][type]["$inc"] ||= Hash.new
            upsert[tag][bom][type]["$inc"]["day.#{day_number}.#{k}"] ||= 0
            upsert[tag][bom][type]["$inc"]["day.#{day_number}.#{k}"] = upsert[tag][bom][type]["$inc"]["day.#{day_number}.#{k}"] + val.to_f
          end
        end
        return upsert
      end

      def self.recompute
        Moonshine::Barrel::Monthly.delete_all
        upsert = {}
        upsert_kv = {}
        c = 0
        Moonshine::Distillery.where(:time.lte => Time.zone.now.utc).each do |d|
          d['distinct'].each do |k,v|
            upsert_kv[k] ||= Hash.new
            upsert_kv[k][v.to_s] ||= Hash.new
            upsert_kv[k][v.to_s] = upsert_kv[k][v.to_s].deep_merge(Moonshine::Barrel::Monthly.bulk_log(d, upsert_kv[k][v.to_s].dup, true))
          end
          
          upsert = upsert.deep_merge(Moonshine::Barrel::Monthly.bulk_log(d, upsert.dup))

          c = c + 1
          if(c > 10000)
            Moonshine::Barrel::Monthly.bulk_insert(upsert)
            Moonshine::Barrel::Monthly.bulk_insert_kv(upsert_kv)
            upsert = {}
            upsert_kv = {}
            c = 0
          end
        end
        Moonshine::Barrel::Monthly.bulk_insert(upsert)
        Moonshine::Barrel::Monthly.bulk_insert_kv(upsert_kv)
      end

      def self.reset
        Moonshine::Barrel::Monthly.all.each do |m|
          m.day = {}
          m.save
        end
      end

      index ({"time" => 1, "type" => 1, "tag" => 1, "fkey" => 1, "fval" => 1})
      
      

      ### should be helper class
      def self.two_digit_day(time)
        sprintf '%02d', time.day
      end
    end
  end
end