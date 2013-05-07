module Moonshine
  class Barrel
    include Mongoid::Document
    # embeds_many :data_points

    def self.hooks(d = Distillery.new)
      ## make this faster ##
      time = d['time'].in_time_zone("Pacific Time (US & Canada)")
      year = time.beginning_of_year
      month = time.beginning_of_month
      day = time.beginning_of_day
      hour = time.beginning_of_hour
      b = Barrel.create(
          :times => {
            :y => year,
            :m => month,
            :d => day,
            :h => hour },
          :e => d.type,
          :t => time
          )
      b.update_attributes(:d => d.data)
      b.save
      # puts Barrel.collection.find(:_id => b['_id']).first.to_s
    end
  end
end
