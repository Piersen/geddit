module Core
  module Shapes
    class Rectangle

      def initialize position, size
        @position = position
        @size = size
      end

      def contains point
        return false unless ((@position.x..@position.x+@size.x).cover? point.x) && ((@position.y..@position.y+@size.y).cover? point.y)
        true
      end

      def is_in_proximity proximity, point
        return true if contains point
        x = [[@position.x, point.x].max, @position.x+@size.x].min
        y = [[@position.y, point.y].max, @position.x+@size.y].min
        projection = Vector2.new x, y
        return true if point.distance(projection) <= proximity
        false
      end

      def to_s
        'x: ' + @position.x.to_s + ' y: ' + @position.y.to_s + ' width: ' + @size.x.to_s + ' height: ' + @size.y.to_s
      end

    end
  end
end
