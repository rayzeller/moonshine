module Moonshine
  module Observer
    require 'delayed_job'

    extend ActiveSupport::Concern
    included do
      after_commit :ferment, :on => :create, :if => lambda {|o| (!Rails.env.test? && !Rails.env.development?)}
      after_commit :ferment_without_delay, :on => :create, :if => lambda {|o| (Rails.env.test? || Rails.env.development?)}
    end
    module InstanceMethods

      def ferment
        Moonshine.send(self.fermenter.new(self).as_json)
      end
      handle_asynchronously :ferment
    end 
  end
end