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
        day_number = time.day
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
                  Moonshine::Barrel::Monthly.collection.find({:tag => tag, :time => time, :type => type, :fkey => key, :fval => value}).upsert(u)
                end
              end
            end
          end
        end
      end

      def self.bulk_log(d, upsert, filter = false)
        tags = (d['tags'].nil? || d['tags'].empty?) ? ["_all"] : d['tags']
        time = d['time'].in_time_zone("Pacific Time (US & Canada)")
        bom = time.beginning_of_month.utc
        type = d['type']
        d['summed'] =  d['summed'].nil? ? Hash.new : d['summed']
        d['distinct'] =  d['distinct'].nil? ? Hash.new : d['distinct']
        day_number = time.day

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
            upsert[tag][bom][type]["$inc"]["day.#{day_number}.#{k}"] = upsert[tag][bom][type]["$inc"]["day.#{day_number}.#{k}"] + val
          end
        end
        return upsert
      end

      def self.reset
        Moonshine::Barrel::Monthly.all.each do |m|
          m.day = {}
          m.save
        end
      end

      index ({"time" => 1, "type" => 1, "tag" => 1, "fkey" => 1, "fval" => 1})
    end
  end
end