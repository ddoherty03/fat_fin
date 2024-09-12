module FatFin
  module DateExtension
    refine Date do
      def month_diff(d, whole = false)
        case d
        when Date
          # Put dates in d0, d1 order
          if self < d
            k = -1
            d0 = self
            d1 = d
          else
            k = 1
            d0 = d
            d1 = self
          end
          # If both dates are last of month, return only
          # whole months
          whole = true if last_of_month? && d.last_of_month?

          # Count number of years
          m = (d1.year - d0.year) * 12
          m += (d1.month - d0.month)
          m += (d1.day - d0.day) / 30.0 unless whole
          k * m
        else
          raise ArgumentError
        end
      end

      def whole_month_diff(d)
        month_diff(d, true)
      end

      def is_leap?
        y = year
        (y % 4 == 0 && y % 100 != 0) || y % 400 == 0
      end

      def last_of_feb?
        return false unless month == 2

        day == if is_leap?
                 29
               else
                 28
               end
      end

      def last_of_month?
        if [1, 3, 5, 7, 8, 10, 12].include?(month) && day == 31
          true
        elsif [4, 6, 9, 11].include?(month) && day == 30
          true
        elsif last_of_feb?
          true
        else
          false
        end
      end
    end
  end
end
