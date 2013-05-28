require 'time'
require "active_support/time_with_zone"
require 'active_support/core_ext/time/zones'
require 'date'
require 'moonshine/version'
require 'mongoid'
require 'active_record'
require 'deep_merge'
require 'delayed_job'


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
  autoload :Monthly, 'moonshine/barrel/monthly'
  autoload :Lifetime, 'moonshine/barrel/lifetime'
  autoload :Distillery, 'moonshine/distillery'
  autoload :Fermenter, 'moonshine/fermenter'
  autoload :Observer, 'moonshine/observer'
  autoload :Checksum, 'moonshine/checksum'

  def self.checksum(object)
    object.to_moonshine
  end

  def self.send(options = {})
    Distillery.create(options)
  end

  def self.bootleg(options = {})
    ## TODO validations ##
    start_time = options[:start].present? ? options[:start].in_time_zone("Pacific Time (US & Canada)") : DEFAULT_START.call
    stop_time = options[:stop].present? ? options[:stop].in_time_zone("Pacific Time (US & Canada)") : DEFAULT_STOP.call
    step = options[:step].present? ? options[:step] : DEFAULT_STEP ## HMMMMMMM -- all time??? -- comeback to this
    
    only = options[:only].present? ? options[:only] : []

    type = options[:type]
    key = options[:key]
    sort = options[:sort]
    order = options[:order]
    limit = options[:limit].present? ? options[:limit] : 50
    offset = options[:offset].present? ? options[:offset] : 0
 
    tags = options[:tags].present? ? options[:tags] : ['_all']
    ## distinct comes later
    metric = options[:metric] ## sum, count
    fkey = options[:filter_key].nil? ? '' : options[:filter_key]
    fval = options[:filter_value].nil? ? '' : options[:filter_value]
    target = options[:target].nil? ? '' : options[:target]

    groups = options[:groups].nil? ? {} : options[:groups]

    raise Exception if type.nil?
    return count_from_barrel(start_time, stop_time, type, tags) if metric == 'count'
    return all_from_barrel(start_time, stop_time, type, tags, only, fkey, fval) if metric == 'all'
    return lifetime(type, fkey, fval, target, {:only => only, :limit => limit, :offset => offset}) if metric == 'lifetime'
    ## automatically precalculate date fields, include data field

    filters = options[:filters].nil? ? {}: options[:filters]

    project_hash = {"$project" => 
      {
        "year"    => { "$year" => "$time"}, "month" => { "$month" => "$time"},
        "day"   => { "$dayOfMonth" => "$time"}, "data" => "$data", "tags" => "$tags"      }
    }

    ##default group by day

    group_hash = {"$group" => 
      {
        "_id"    => { "year" => "$year", "month" => "$month", "day" => "$day"},
      }
    }

    sort_hash =  { "$sort" => { _id: 1 } }
    ## sum up, or count stuff ##
    group_hash["$group"]["metric"] = {"$sum" => "$data.#{key.to_s}"} if metric == "sum"
    group_hash["$group"]["metric"] = {"$sum" => 1} if metric == "count"

    filter_hash = Hash.new
    filter_hash["time"] = {"$gte" => start_time.utc, "$lte" => stop_time.utc}

    filters.each do |filter_key, filter_value|
      # validate that data contains this filter
      filter_hash["data.#{filter_key.to_s}"] = filter_value.is_a?(Array) ? {"$gte" => filter_value[0], "$lte" => filter_value[1]} : filter_value
    end
    filter_hash["type"] = type
    filter_hash["tags"] = {"$all" => tags} if !tags.empty?

    match_hash = {"$match" => filter_hash } if filter_hash.present?

    raise Exception if start_time > stop_time
    raise Exception if metric.nil?

    opts = Array.new
    opts.push(match_hash) if match_hash.present?
    opts.push(project_hash) if project_hash.present?
    opts.push(group_hash) if group_hash.present?
    opts.push(sort_hash) if sort_hash.present?

    hash = Distillery.collection.aggregate(opts)
    hash
  end

  def self.reset
    #USE DB Refresher, and make this method private maybe##
    Distillery.destroy_all
    Barrel::Monthly.destroy_all
    Distillery.create_indexes
    Barrel::Monthly.create_indexes
  end

  DEFAULT_START = Proc.new { Time.zone.now.beginning_of_day }
  DEFAULT_STOP = Proc.new { Time.zone.now }
  DEFAULT_STEP = 24 * 60 * 60 ## 86400 seconds

  private
    def self.all_from_barrel(start_time, stop_time, type, tags, only, fkey, fval)
      tags = tags.dup.empty? ? ["_all"] : tags
      h = Hash.new

      tags.each do |tag|
        h[tag] ||= Hash.new
        Moonshine::Barrel::Monthly.where(:time.gte => start_time.beginning_of_month.utc, :time.lte => stop_time.beginning_of_month.utc, :tag => tag, :type => type, :fkey => fkey, :fval => fval).each do |m|
          time = m.time
          
          m.day.each do |key, val|
            day = (time+(key.to_i-1).days).utc
            if (start_time.utc <= day && stop_time.utc >= day)
              h[tag][day] ||= Hash.new
              h[tag][day]['count'] = val['_c']
              val.each do |key, data|
                h[tag][day][key] = data if (key.in?(only) && !only.empty?)
              end
            end
          end
        end
      end
      h
    end

    def self.lifetime(type, fkey, fval, target_key, options = {})
      h = Hash.new
      h['users'] = {}
      limit = (options[:limit].to_i)
      only = (options[:only] || [])
      # sort = (options[:sort] || '1')
      # sort = sort == '1' ? "ASC" : "DESC"
      offset = (options[:offset].to_i)
      # order = (options[:order] || 'count')
      # order = '_c' if order == 'count'
      users = []

      only_hash = {}
      only_hash = {}
      group_hash = {'$group' => {'_id' => {}}}
      only_hash['id'] = "$data.id"
      only_hash['count'] = "$data._c"
      group_hash['$group']['_id']['id'] = "$id"
      group_hash['$group']['_id']['count'] = "$count"

      only.each do |o| 
        group_hash['$group']['_id']["#{o}"] = "$#{o}" if o != "count"
        only_hash[o] = "$data.#{o}" if o != "count"
      end
      project_hash = {"$project" => only_hash}
      match_hash = {"$match" => {
          'fkey' => fkey,
          'fval' => fval,
          'skey' => target_key,
          'type' => type,
        }
      }
      sort_hash = {'$sort' => {'count' => 1}}
      limit_hash = {'$limit' => limit}
      skip_hash = {'$skip' => offset}
     
      result =  Moonshine::Barrel::Lifetime.collection.aggregate([match_hash,project_hash,sort_hash,group_hash,skip_hash,limit_hash])
      result
    end

    def self.count_from_barrel(start_time, stop_time, type, tags)
      tag = tags.empty? ? "_all" : tags.first
      count = 0
      Moonshine::Barrel::Monthly.where(:time.gte => start_time.beginning_of_month.utc, :time.lte => stop_time.beginning_of_month.utc, :tag => tag, :type => type).where({:fkey => '', :fval => ''}).each do |m|
        time = m.time
        
        m.day.each do |key, val|
          day = (time+(key.to_i-1).days).utc
          count = (count + val['_c']) if (start_time.utc <= day && stop_time.utc >= day)
        end
      end
      {"count" => count}
    end

end