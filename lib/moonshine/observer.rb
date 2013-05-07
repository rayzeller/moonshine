module Moonshine
  module Observer
    extend ActiveSupport::Concern
    included do
      after_commit :ferment, :on => :create
    end
    module InstanceMethods
      def ferment
        Moonshine.send(self.fermenter.new(self).as_json)
      end
    end 
  end
end