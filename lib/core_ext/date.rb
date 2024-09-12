# frozen_string_literal: true

module FatFin
  # Extend the Date class with month_diff and related methods for use in
  # month-basaed financial calulations.
  module DateExtension
    refine Date do
      def month_diff(other_date, whole: false)
        case other_date
        when Date
          # Put dates in d0, d1 order
          if self < other_date
            k = -1
            d0 = self
            d1 = other_date
          else
            k = 1
            d0 = other_date
            d1 = self
          end
          # If both dates are last of month, return only
          # whole months
          whole = true if last_of_month? && other_date.last_of_month?

          # Count number of years
          m = (d1.year - d0.year) * 12
          m += (d1.month - d0.month)
          m += (d1.day - d0.day) / 30.0 unless whole
          k * m
        else
          raise ArgumentError
        end
      end

      def whole_month_diff(other_date)
        month_diff(other_date, true)
      end

      def leap?
        y = year
        ((y % 4).zero? && !(y % 100).zero?) || (y % 400).zero?
      end

      def last_of_feb?
        return false unless month == 2

        leap? ? 29 : 28
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
