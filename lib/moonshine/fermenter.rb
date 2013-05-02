module Moonshine
  class Fermenter
    class_attribute :_data
    class_attribute :_type
    class_attribute :_time

    self._data = {}
    self._time = Time.zone.now

    class << self

      def data(*attrs)

        self._data = _data.dup

        attrs.each do |attr|
          if Hash === attr
            attr.each {|attr_real, key| data_point attr_real, :key => key }  ## comment out??
          else
            data_point attr
          end
        end
      end

      def type(t)
        self._type = t
      end

      def time(t)
        self._time = t
      end

      def data_point(attr, options={})
        self._data = _data.merge(attr.is_a?(Hash) ? attr : {attr => options[:key] || attr.to_s.gsub(/\?$/, '').to_sym})

        attr = attr.keys[0] if attr.is_a? Hash

        unless method_defined?(attr)
          define_method attr do
            object.send(attr.to_sym)
          end
        end

      end

      def model_class
        name.sub(/Fermenter$/, '').constantize
      end

    end
    
    attr_reader :object, :options

    def initialize(object, options={})
      @object, @options = object, options
    end

    def as_json(options = {})
      return nil if @object.nil?

      class_name = self.class.name.demodulize.underscore.sub(/_fermenter$/, '') unless self.class.name.blank?
      self._type ||= class_name

      @options[:hash] = hash = {}
      hash[:data] = self._data
      hash[:time] = self._time
      hash[:type] = self._type
      hash
    end

  end
end