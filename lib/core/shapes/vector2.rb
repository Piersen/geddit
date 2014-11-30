module Core
  module Shapes
    class Vector2
      def initialize x, y
        @x = x
        @y = y
      end

      def distance point
        return Math.sqrt((x-point.x) ** 2 + (y-point.y) ** 2)
      end

      def to_s
        'x: ' + @x.to_s + ' y: ' + @y.to_s
      end

      attr_accessor :x, :y
    end
  end
end
