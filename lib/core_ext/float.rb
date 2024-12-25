module FatFin
  module FloatNearly
    refine Float do
      # Compare floating point number for equality in $POINTS places
      def nearly?(other, places = 7)
        tX = sprintf("%0.#{places}f", self)
        tY = sprintf("%0.#{places}f", other)
        tX == tY
      end
    end
  end
end
