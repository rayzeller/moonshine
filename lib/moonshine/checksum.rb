module Moonshine
  module Checksum
    extend ActiveSupport::Concern
    
    included do
      scope :sent_to_moonshine, lambda { |time_attr, start, stop| where("#{time_attr} >= ? AND #{time_attr} <= ?", start, stop) }
    end

    module ClassMethods

      def checksum(start = Time.zone.now, stop = Time.zone.now)
        errors = Array.new
        checksum = ''
        f = self.fermenter
        self.sent_to_moonshine(f.get_time.to_s, start, stop).find_each do |object|
          json = f.new(object).as_json
          errors.push(object.id => json) if !Distillery.where(json).exists?
        end
        count = self.sent_to_moonshine(f.get_time.to_s, start, stop).count
        dist_count = Distillery.where(:type => f.get_type).where(:time.gte => start, :time.lte => stop).count

        errors.push("count discrepancy" => "#{count} --- #{dist_count}") if dist_count != count
        return errors.empty? ? true : errors
      end

      ## no deleting events, only allow events to get resent ##
      ## maybe mark events as unusable ##
      def repair(start = Time.zone.now, stop = Time.zone.now)
        f = self.fermenter
        self.sent_to_moonshine(f.get_time.to_s, start, stop).find_each do |object|
          json = f.new(object).as_json
          Moonshine.send(json) if !Distillery.where(json).exists?
        end
      end
    end
   
  end
end
