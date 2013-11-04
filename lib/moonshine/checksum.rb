module Moonshine
  module Checksum
    extend ActiveSupport::Concern

    included do
      scope :sent_to_moonshine, lambda { |time_attr, start, stop| where("#{time_attr} >= ? AND #{time_attr} <= ?", start, stop) }
    end

    module ClassMethods

      # checks whether the Distillery contains the exact same set of events
      #   as Class
      #
      #  ex: Order.checksum(Time.zone.now - 1.month, Time.zone.now.beginning_of_day)
      # => double checks that all Order events in the past month have been sent over to the distillery
      #
      def checksum(start = Time.zone.now, stop = Time.zone.now)
        errors = Array.new
        checksum = ''
        f = self.fermenter
        self.sent_to_moonshine(f.get_time.to_s, start, stop).find_each do |object|
          json = f.new(object).as_json
          json.dup.each do |k, v|
            json[k] = v.mongoize
          end
          errors.push(object.id => json) if !Distillery.where(json).exists?
        end
        count = self.sent_to_moonshine(f.get_time.to_s, start, stop).count
        dist_count = Distillery.where(:type => f.get_type).where(:time.gte => start, :time.lte => stop).count

        errors.push("count discrepancy" => "#{count} --- #{dist_count}") if dist_count != count
        return errors.empty? ? true : errors
      end

      def get_count(start = Time.zone.now, stop = Time.zone.now)
        f = self.fermenter
        count = self.sent_to_moonshine(f.get_time.to_s, start, stop).count
        dist_count = Distillery.where(:type => f.get_type).where(:time.gte => start, :time.lte => stop).count
        return dist_count > count
      end
      

      # allows you to resend old events to the Distillery
      # basically the same as resyncing Moonshine to your Models
      # 
      #  ex: Order.repair(Time.zone.now - 1.month, Time.zone.now.beginning_of_day)
      # => sends over all Order events in the past month (doesn't resend)
      #
      # => TODO:
      ## no deleting events, only allow events to get resent ##
      ## maybe mark events as unusable ##
      ##
      ## bulk inserts, bulk callbacks
      def repair(start = Time.zone.now, stop = Time.zone.now)
        f = self.fermenter
        
        ## start over if distillery has too many events
        # Distillery.where(:type => f.get_type).where(:time.gte => start, :time.lte => stop).delete_all if get_count(start,stop)

        self.sent_to_moonshine(f.get_time.to_s, start, stop).find_each do |object|
          json = f.new(object).as_json
          Moonshine.send(json) if !Distillery.where(:type => json[:type], :fid => json[:fid]).exists?
        end
        return true
      end
    end
   
  end
end
