module Core
  module Preprocessor
    class InterfaceObject

      def initialize rect, params
        @rect = rect
        @params = params
      end

      attr_accessor :rect, :params
    end
  end
end