require 'time'
require "active_support/time_with_zone"
require 'active_support/core_ext/time/zones'
require 'date'
require 'moonshine/version'
require 'mongoid'

module ActiveModel::MoonshineSupport
  extend ActiveSupport::Concern

  module ClassMethods #:nodoc:
    if "".respond_to?(:safe_constantize)
      def fermenter
        "#{self.name}Fermenter".safe_constantize
      end
    else
      def fermenter
        begin
          "#{self.name}Fermenter".constantize
        rescue NameError => e
          raise unless e.message =~ /uninitialized constant/
        end
      end
    end
  end

  # Returns a model serializer for this object considering its namespace.
  def fermenter
    self.class.fermenter
  end

end

ActiveSupport.on_load(:active_record) do
  include ActiveModel::MoonshineSupport
end

module Moonshine
  # require 'mongoid'
  PACIFIC_TIME_ZONE = "Pacific Time (US & Canada)"

  Time.zone = PACIFIC_TIME_ZONE

  autoload :Barrel, 'moonshine/barrel'
  autoload :Distillery, 'moonshine/distillery'
  autoload :Fermenter, 'moonshine/fermenter'

  def self.checksum(object)
    object.to_moonshine
  end

  def self.send(options = {})
    Distillery.create(options)
  end

  def self.get(options = {})
    ## TODO validations ##
    start_time = options[:start].present? ? options[:start].in_time_zone("Pacific Time (US & Canada)") : DEFAULT_START.call
    stop_time = options[:stop].present? ? options[:stop].in_time_zone("Pacific Time (US & Canada)") : DEFAULT_STOP.call
    step = options[:step].present? ? options[:step] : DEFAULT_STEP
    metric = options[:metric]
    type = options[:type]
    key = options[:key]

    raise Exception if start_time > stop_time
    raise Exception if metric.nil?
    raise Exception if type.nil?
    raise Exception if key.nil?
    raise Exception if metric == "distinct" && Barrel.where(:type => "#{type}_#{key}").first.value.is_a?(Integer)
    raise Exception if metric == "distinct.count" && Barrel.where(:type => "#{type}_#{key}").first.value.is_a?(Integer)
    raise Exception if metric == "sum" && Barrel.where(:type => "#{type}_#{key}").first.value.is_a?(String)

    if(metric == "sum")
      # Barrel.between({:timestamp => start_time..stop_time}).where(:type => "#{type}_#{key}").sum(:value)
      hash = Hash.new
      date_block = start_time

      Barrel.between({:timestamp => start_time..stop_time}).where(:type => "#{type}_#{key}").map_reduce(MAP, REDUCE).out(replace: "mr-results").each do |document|
        date = document['_id'].to_datetime
        count = document['value']
        while (date >= date_block + step)
          date_block = (date_block + step)
        end
        hash[date_block] ||= 0
        hash[date_block] = hash[date_block] + count
      end
      hash
    elsif(metric == "distinct")
      hash = Hash.new
      date_block = start_time
      values = []

      Barrel.between({:timestamp => start_time..stop_time}).where(:type => "#{type}_#{key}").map_reduce(MAP, DISTINCT_REDUCE).out(replace: "mr-results").each do |document|
        date = document['_id'].to_datetime
        values = values + document['value']

        while (date >= date_block + step)
          date_block = (date_block + step)
          values = document['value']
        end

        hash[date_block] ||= 0
        hash[date_block] = values.uniq
      end
      hash
    elsif(metric == "distinct.count")
      hash = Hash.new
      date_block = start_time
      values = []

      Barrel.between({:timestamp => start_time..stop_time}).where(:type => "#{type}_#{key}").map_reduce(MAP, DISTINCT_REDUCE).out(replace: "mr-results").each do |document|
        date = document['_id'].to_datetime
        values = values + document['value']

        while (date >= date_block + step)
          date_block = (date_block + step)
          values = document['value'].uniq
        end

        hash[date_block] ||= 0
        hash[date_block] = values.uniq.count

        
      end
      hash
    else
      return []
    end
  end

  def self.reset
    #USE DB Refresher, and make this method private maybe##
    Distillery.destroy_all
    Barrel.destroy_all
  end

  DEFAULT_START = Proc.new { Time.zone.now.beginning_of_day }
  DEFAULT_STOP = Proc.new { Time.zone.now }
  DEFAULT_STEP = 24 * 60 * 60 ## 86400 seconds

  MAP = %Q{
    function() {
      emit(new Date(this.year, this.timestamp.getMonth(), this.day), this.value);
    }
  }

  REDUCE = %Q{
    function(key, values) {
      var result = { value: 0 };
      values.forEach(function(value) {
        result.value += value;
      });
      return result;
    }
  }

  DISTINCT_REDUCE = %Q{
    function(key, values) {
      var result = { value: [] };
      values.forEach(function(value) {
        result.value = result.value.concat(value);
      });
      return result;
    }
  }

  

end