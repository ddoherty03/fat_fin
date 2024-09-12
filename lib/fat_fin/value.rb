# frozen_string_literal: true

module FatFin
  # This class contains a value at a date.  The value must be positive.
  class Value
    using DateExtension

    attr_reader :date, :amount

    def initialize(amount = 0.0, date: Date.today)
      @amount = amount
      @date = Date.ensure_date(date)
    end

    def to_s
      "Val[#{@amount} @ #{@date}]"
    end
  end
end
