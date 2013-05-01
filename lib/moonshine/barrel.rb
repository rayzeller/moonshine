module Moonshine
  class Barrel
    include Mongoid::Document

    def self.hooks(d = Distillery.new)
      ## make this faster ##
      time = d['time'].in_time_zone("Pacific Time (US & Canada)").beginning_of_day
      year = time.beginning_of_year.strftime("%Y")
      month = time.beginning_of_month.strftime("%m")
      day = time.beginning_of_day.strftime("%d")
      d.data.each do |data_key, data_value|
        self.increment_sum(time, year, month, day, data_key, data_value, d.type) if data_value.is_a?(Integer)
        self.add_distinct_values(time, year, month, day, data_key, data_value, d.type) if data_value.is_a?(String)
      end
    end

    private
      def self.increment_sum(timestamp, year, month, day, data_key, data_value, type)
        b = Barrel.find_or_create_by(
          :timestamp => timestamp,
          :year => year,
          :month => month,
          :day => day,
          :type => "#{type}_#{data_key.to_s}")
        b.inc(:value, data_value)
        b.save
      end

      def self.add_distinct_values(timestamp, year, month, day, data_key, data_value, type)
        b = Barrel.find_or_create_by(
          :timestamp => timestamp,
          :year => year,
          :month => month,
          :day => day,
          :type => "#{type}_#{data_key.to_s}")
        b.add_to_set(:value, data_value)
        b.save
      end
  end
end
