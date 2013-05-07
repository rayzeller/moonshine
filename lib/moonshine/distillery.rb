module Moonshine
  class Distillery
    include Mongoid::Document

    after_create :hooks

    def self.checksum_key(type)
      checksum = ''
      scoped = self.where(:type => type).asc(:time)
      scoped.each do |item|
        checksum = checksum + item.to_s
      end
      Digest::MD5.hexdigest "#{scoped.count}-#{checksum}"
    end

    def to_s
      "#{self.data}-#{self.time}-#{self.type}"
    end

    protected
      def hooks
        Barrel.hooks(self)
      end

      def as_json
        hash = {}
        hash[:data] = self.data
        hash[:time] = self.time
        hash[:type] = self.type
        hash
      end

      



  end
end