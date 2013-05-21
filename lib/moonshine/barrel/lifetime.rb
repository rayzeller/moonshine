module Moonshine
  module Barrel
    class Lifetime
      include Mongoid::Document

      field :type, :type => String
      field :fkey, :type => String
      field :fval, :type => String

      def self.hooks(fkey, fval, skey, sval, attributes)
        add_to_set = {}
        inc = {"#{skey}.#{sval}._c" => 1}
        attributes.each do |a, val|
          inc["#{skey}.#{sval}.#{a}"] = val
        end
        atomic = {"$inc" => inc}
        atomic
      end

      def self.bulk_insert(upsert)
        upsert.each do |fkey, fvals|
          fvals.each do |fval, types|
            types.each do |type, u|
              Moonshine::Barrel::Lifetime.collection.find({:type => types, :fkey => fkey, :fval =>fval}).upsert(u)
            end
          end
        end
      end


      def self.bulk_log(d, upsert)
        type = d['type']
        d['distinct'].each do |k, v|
          upsert[k] ||= Hash.new
          upsert[k][v] ||= Hash.new
          upsert[k][v][type] ||= Hash.new
          d['distinct'].each do |skey, sval|
            upsert[k][v][type]["$inc"] ||= Hash.new
            upsert[k][v][type]["$inc"]["#{skey}.#{val}._c"] ||= 1
            d['summed'].each do |sumk, sumval|
              upsert[k][v][type]["$inc"] ||= Hash.new
              upsert[k][v][type]["$inc"]["#{skey}.#{sval}.#{sumk}"] ||= 0
              upsert[k][v][type]["$inc"]["#{skey}.#{sval}.#{sumk}"] = upsert[type]["$inc"]["#{skey}.#{sval}.#{sumk}"] + sumval
            end
          end
        end
        return upsert
      end

      def self.log_hit(d, filter=false)
        type = d['type']
        upsert = {type => {}}
        d['distinct'].each do |k, v|
          d['distinct'].each do |skey, sval|
            upsert[type]["$inc"] ||= Hash.new
            upsert[type]["$inc"]["#{skey}.#{sval}._c"] ||= 1
            d['summed'].each do |sumk, sumval|
              upsert[type]["$inc"] ||= Hash.new
              upsert[type]["$inc"]["#{skey}.#{sval}.#{sumk}"] ||= 0
              upsert[type]["$inc"]["#{skey}.#{sval}.#{sumk}"] = upsert[type]["$inc"]["#{skey}.#{sval}.#{sumk}"] + sumval
            end
            Moonshine::Barrel::Lifetime.collection.find({:type => type, :fkey => k, :fval => v.to_s}).upsert(upsert[type])
          end          
        end
      end

      def self.recompute
        Moonshine::Barrel::Lifetime.delete_all
        upsert = {}
        c = 0
        Moonshine::Distillery.where(:time.lte => Time.zone.now.utc).each do |d|
          upsert = upsert.deep_merge(Moonshine::Barrel::Lifetime.bulk_log(d, upsert.dup))
          
          c = c + 1
          if(c > 10000)
            Moonshine::Barrel::Lifetime.bulk_insert(upsert)
            upsert = {}
            c = 0
          end
        end
        Moonshine::Barrel::Lifetime.bulk_insert(upsert)
      end

      index ({"type" => 1, "fkey" => 1, "fval" => 1})
      
    end
  end
end