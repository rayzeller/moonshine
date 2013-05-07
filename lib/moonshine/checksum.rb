module Moonshine
  module Checksum
    extend ActiveSupport::Concern
    included do
      scope :sent_to_moonshine, lambda { |time_attr, start, stop| where('? >= ? AND ? <= ?', time_attr, time_attr, start, stop) }
    end
    module ClassMethods
      def checksum(start = Time.zone.now, stop = Time.zone.now)
        errors = Array.new
        checksum = ''
        f = self.fermenter
        self.sent_to_moonshine(fermenter.get_time.to_s, start, stop).find_each do |object|
          json = f.new(object).as_json
          errors.push(object.id => json) if !Distillery.where(json).exists?
        end
        return errors.empty? ? true : errors
      end
    end
   
  end
end
