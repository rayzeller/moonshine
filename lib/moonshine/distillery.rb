module Moonshine
  class Distillery
    include Mongoid::Document

    after_create :hooks

    protected
      def hooks
        Barrel.hooks(self)
      end



  end
end