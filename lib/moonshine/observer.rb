module Moonshine
  module Observer
    extend ActiveSupport::Concern
    included do
      after_create :ferment
    end
    module InstanceMethods
      def ferment
        Moonshine.send(self.fermenter.new(self).as_json)
      end
    end 
  end
end