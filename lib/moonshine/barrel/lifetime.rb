module Moonshine
  module Barrel
    class Lifetime
      include Mongoid::Document

      field :type, :type => String
      field :fkey, :type => String
      field :fval, :type => String
      field :data, :type => Array
      field :skey, :type => String

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
              Moonshine::Barrel::Lifetime.collection.find({:type => type, :fkey => fkey, :fval =>fval}).upsert(u)
            end
          end
        end
      end

      def self.insert(upsert)
        upsert.each do |fkey, fvals|
          fvals.each do |fval, types|
            types.each do |type, u|
              Moonshine::Barrel::Lifetime.collection.find({:type => type, :fkey => fkey, :fval =>fval}).upsert(u)
            end
          end
        end
      end


      def self.bulk_log(d, upsert)
        type = d['type']
        d['distinct'].each do |k, v|
          upsert[k] ||= Hash.new
          upsert[k][v.to_s] ||= Hash.new
          upsert[k][v.to_s][type] ||= Hash.new
          d['distinct'].each do |skey, sval|
            upsert[k][v.to_s][type]["$inc"] ||= Hash.new
            upsert[k][v.to_s][type]["$inc"]["#{skey}.#{sval}._c"] ||= 0
            upsert[k][v.to_s][type]["$inc"]["#{skey}.#{sval}._c"] = upsert[k][v.to_s][type]["$inc"]["#{skey}.#{sval}._c"] + 1
            d["data"].each do |dkey, dval|
              upsert[k][v.to_s][type]["$push"] ||= Hash.new
              upsert[k][v.to_s][type]["$push"]["#{skey}.#{sval}.#{dkey}"] = dval
            end
            d['summed'].each do |sumk, sumval|
              upsert[k][v.to_s][type]["$inc"]["#{skey}.#{sval}.#{sumk}"] ||= 0
              upsert[k][v.to_s][type]["$inc"]["#{skey}.#{sval}.#{sumk}"] = upsert[k][v.to_s][type]["$inc"]["#{skey}.#{sval}.#{sumk}"] + sumval
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
            upsert[type] = Hash.new
            upsert[type]['$inc'] = Hash.new
            upsert[type]["$push"] = Hash.new
            upsert[type]["$inc"]["data.$._c"] = 1
            d["data"].each do |dkey, dval|
              upsert[type]["$push"]["data.$.#{dkey}"] = dval
            end
            d['summed'].each do |sumk, sumval|
              upsert[type]["$inc"]["data.$.#{sumk}"] = sumval
            end
            Moonshine::Barrel::Lifetime.collection.find({:type => type, :fkey => k, :fval => v.to_s, :skey => skey}).upsert({'$addToSet' => {"data" => {"id" => sval.to_s}}})
            Moonshine::Barrel::Lifetime.collection.find({:type => type, :fkey => k, :fval => v.to_s, :skey => skey, "data.id" => sval.to_s}).upsert(upsert[type])
          end
        end
      end

      def self.recompute
        Moonshine::Barrel::Lifetime.delete_all
        # upsert = {}
        # c = 0
        Moonshine::Distillery.where(:time.lte => Time.zone.now.utc).each do |d|
          # upsert = upsert.deep_merge(Moonshine::Barrel::Lifetime.bulk_log(d, upsert.dup))
          Moonshine::Barrel::Lifetime.log_hit(d)
          
          # c = c + 1
          # if(c > 10000)
            # Moonshine::Barrel::Lifetime.bulk_insert(Moonshine::Barrel::Lifetime.bulk_log(d, {}))
            # upsert = {}
            # c = 0
          # end
        end
        # Moonshine::Barrel::Lifetime.bulk_insert(upsert)
      end

      index ({"type" => 1, "fkey" => 1, "fval" => 1, "skey" => 1, "data.id" => 1})
      index ({"data._c" => -1})
      
    end
  end
end