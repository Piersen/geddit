module Core
  module Shapes
    class Rectangle

      def initialize position, size
        @frame = position
        @size = size
      end

      def contains point
        return false unless ((@frame.x..@frame.x+@size.x).cover? point.x) && ((@frame.y..@frame.y+@size.y).cover? point.y)
        true
      end

      def to_s
        'x: ' + @frame.x.to_s + ' y: ' + @frame.y.to_s + ' width: ' + @size.x.to_s + ' height: ' + @size.y.to_s
      end

    end
  end
end
