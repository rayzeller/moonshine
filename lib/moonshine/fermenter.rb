module Moonshine
  class Fermenter
    attr_reader :object, :options
    
    def initialize(object, options={})
      @object, @options = object, options
    end

    def to_json(*args)
      {
        :type => @object.class.name,
        :time => Time.zone.now,
        :data => {
          :event => 'event'
        }
      }
    end
  end
end