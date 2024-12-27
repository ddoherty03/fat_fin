module FatFin
  module FloatExtension
    refine Float do
      def fraction
        abs - floor.abs
      end

      # Return the number of digits after decimal, or 0 for numbers greater
      # than 1.
      def precision
        return 0 if abs > 1.0

        Math.log(abs, 10).abs.round(0)
      end

      # Return whether self is within abs_tol of other.
      def close_to?(other, abs_tol: 0.00000001, rel_tol: abs_tol)
        return true if self == other.to_f
        return false if infinite? || other.infinite?
        return false if nan? || other.nan?

        prec = abs_tol.precision
        abs_diff = (round(prec) - other.round(prec)).abs.round(prec)
        abs_diff <= [abs_tol, rel_tol * [abs, other.abs].max].max
      end
    end
  end
end
