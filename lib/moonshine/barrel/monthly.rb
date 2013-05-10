module Moonshine
  module Barrel
    class Monthly
      include Mongoid::Document

      field :time, :type => DateTime
      field :type, :type => String
      field :tag, :type => String
      field :day, type: Hash

      def self.hooks(tag, time, attributes)
        day_number = time.day
        add_to_set = {}
        atomic = {'$inc' => {"day.#{day_number}._c" => 1} }
        attributes.each do |a, val|
          add_to_set["day.#{day_number}.#{a}"] = val
        end
        atomic.merge!({"$addToSet" => add_to_set}) if !add_to_set.empty?
        atomic
      end

      index ({"time" => 1, "type" => 1, "tag" => 1})
    end
  end
end