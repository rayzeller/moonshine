module Moonshine
  class Fermenter
    ### TODO
    #
    #  add support for associations
    #
    # # # # # # # 

    DEFAULT_TIME = :created_at

    class_attribute :_data
    class_attribute :_type
    class_attribute :_time
    class_attribute :_tags
    class_attribute :_summed_data ## summed datapoints are summed together during aggregation
    class_attribute :_distinct_data ## distinct data is grouped together in a set during aggregations

    self._data = {}
    self._summed_data = {}
    self._distinct_data = {}
    self._tags = {}
    self._time = DEFAULT_TIME

    class << self

      def data(*attrs)

        self._data = _data.dup
        self._summed_data = _summed_data.dup
        self._distinct_data = _distinct_data.dup

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

      def tag(name, options = {})
        self._tags = self._tags.merge(name => options[:if]) if options[:if].is_a?(Proc)
      end

      def get_type
        self._type
      end

      def get_time
        self._time
      end

      def time(t)
        self._time = t
      end

      def data_point(attr, options={})
        if (options[:summed] == true)
          self._summed_data = _summed_data.merge(attr.is_a?(Hash) ? attr : {attr => options[:key] || attr.to_s.gsub(/\?$/, '').to_sym})
        elsif (options[:distinct] == true)
          self._distinct_data = _distinct_data.merge(attr.is_a?(Hash) ? attr : {attr => options[:key] || attr.to_s.gsub(/\?$/, '').to_sym})
        else
          self._data = _data.merge(attr.is_a?(Hash) ? attr : {attr => options[:key] || attr.to_s.gsub(/\?$/, '').to_sym})
        end

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

    def type
      self._type
    end

    def tags
      tags = []
      _tags.each do |name, block|
        tags << name.to_s if (block.call(object) == true)
      end
      tags
    end

    def time
      begin
        object.send self._time
      rescue  NoMethodError
        Time.zone.now
      end
    end

    def data
      _fast_data
      rescue NameError
        method = "def _fast_data\n"

        method << "  h = {}\n"

        _data.each do |name,key|
          method << "  h[:\"#{key}\"] = send(:\"#{name}\")\n"
        end
        method << "  h\nend"

        self.class.class_eval method
        _fast_data
    end

    def distinct_data
      _fast_distinct_data
      rescue NameError
        method = "def _fast_distinct_data\n"

        method << "  h = {}\n"

        _distinct_data.each do |name,key|
          method << "  h[:\"#{key}\"] = send(:\"#{name}\")\n"
        end
        method << "  h\nend"

        self.class.class_eval method
        _fast_distinct_data
    end

    def summed_data
      _fast_summed_data
      rescue NameError
        method = "def _fast_summed_data\n"

        method << "  h = {}\n"

        _summed_data.each do |name,key|
          method << "  h[:\"#{key}\"] = send(:\"#{name}\")\n"
        end
        method << "  h\nend"

        self.class.class_eval method
        _fast_summed_data
    end

    def as_json(options = {})
      return nil if @object.nil?

      class_name = self.class.name.demodulize.underscore.sub(/_fermenter$/, '') unless self.class.name.blank?
      self._type ||= class_name

      @options[:hash] = hash = {}
      hash[:data] = data
      hash[:summed] = summed_data
      hash[:distinct] = distinct_data
      hash[:time] = time
      hash[:type] = type
      hash[:tags] = tags
      hash
    end

    def to_s(options = {})
      return nil if @object.nil?

      class_name = self.class.name.demodulize.underscore.sub(/_fermenter$/, '') unless self.class.name.blank?
      self._type ||= class_name

      "#{data}-#{time}-#{type}"
    end

  end
end