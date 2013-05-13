module Moonshine
  class Distillery
    include Mongoid::Document

    index "time" => 1
    index "type" => 1
    index "tags" => 1
    #cant index :data since it contains dynamic data so might need to move certain stuff to a different table
    field :data, :type => Hash
    field :summed, :type => Hash
    field :distinct, :type => Hash
    field :time, :type => DateTime

    after_create :hooks

    ########
    #
    # Distillery is the first repository for events
    #
    # Queries for sum and totals of data over time are pulled from this collection
    #
    # # # # #  #

    # returns a unique key for an event type, with the intent to match the key of the
    #   checksum_key of the event's fermenter
    #
    def self.checksum_key(type)
      checksum = ''
      scoped = self.where(:type => type).asc(:time)
      scoped.each do |item|
        checksum = checksum + item.to_s
      end
      Digest::MD5.hexdigest "#{scoped.count}-#{checksum}"
    end

    def to_s
      "#{self.data}-#{self.time}-#{self.type}-#{self.summed}-#{self.tags}-#{self.distinct}"
    end

    protected
      # hooks allow post-processing of data for multiple types of queries
      def hooks
        # puts self.as_json
        Barrel.hooks(self)
      end

      # JSON representation of the distillery object... same as what the fermenter sends to it
      def as_json
        hash = {}
        hash[:data] = self.data
        hash[:summed] = self.summed
        hash[:distinct] = self.distinct
        hash[:time] = self.time
        hash[:type] = self.type
        hash[:tags] = self.tags

        hash
      end

      



  end
end