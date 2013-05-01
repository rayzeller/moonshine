require 'moonshine/version'
require 'mongo'
require 'mongoid'

module Moonshine

  autoload :Barrel, 'moonshine/barrel'
  autoload :Distillery, 'moonshine/distillery'

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
      # Barrel.between({:timestamp => start_time..stop_time}).where(:type => "#{type}_#{key}").pluck(:value).flatten.uniq.count
        date = document['_id'].to_datetime
        values = values + document['value']

        hash[date_block] ||= 0
        hash[date_block] = values.uniq.count

        while (date >= date_block + step)
          date_block = (date_block + step)
          values = []
        end
      end
      hash
    else
      return false
    end
  end

  DEFAULT_START = Proc.new { Time.zone.now.beginning_of_day }
  DEFAULT_STOP = Proc.new { Time.zone.now }
  DEFAULT_STEP = 1.day ## 86400 seconds

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