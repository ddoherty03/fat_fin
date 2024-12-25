# frozen_string_literal: true

module FatFin
  # Extend the Date class with month_diff and related methods for use in
  # month-basaed financial calulations.
  module DateExtension
    refine Date do
      def Date.excel(i)
        k = i <= 60 ? 1 : 0
        Date.new(1899, 12, 30) + i + k
      end

      def month_diff(other_date, whole: false)
        other_date = Date.ensure(other_date)
        case other_date
        when Date
          # Put dates in d0, d1 order
          if self < other_date
            factor = -1
            date0 = self
            date1 = other_date
          else
            factor = 1
            date0 = other_date
            date1 = self
          end
          # If both dates are last of month, return only
          # whole months
          whole = true if last_of_month? && other_date.last_of_month?

          # Count number of years
          months = (date1.year - date0.year) * 12
          months += (date1.month - date0.month)
          months += (date1.day - date0.day) / 30.0 unless whole
          factor * months
        else
          raise ArgumentError, "Date#month_diff(other) requires Date or string parseable as a Date"
        end
      end

      def whole_month_diff(other_date)
        month_diff(other_date, true)
      end

      def leap?
        ((year % 4).zero? && !(year % 100).zero?) || (year % 400).zero?
      end

      def last_of_feb?
        return false unless month == 2

        leap? ? 29 : 28
      end

      def last_of_month?
        ([1, 3, 5, 7, 8, 10, 12].include?(month) && day == 31) ||
          ([4, 6, 9, 11].include?(month) && day == 30) ||
          last_of_feb?
      end
    end
  end
end
