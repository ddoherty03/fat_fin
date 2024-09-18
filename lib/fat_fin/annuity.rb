# frozen_string_literal: true

module FatFin
  class Annuity
    attr_reader :years, :amount, :freq

    def initialize(years: 1, amount: 0.0, freq: 1)
      @years = years
      @amount = amount
    end

    def to_s
      "Annuity[#{@years} years of #{@amount}, compounding #{freq} times per year]"
    end

    def present_value(rate: 0.1)
      # Return present value using rate as the annual discount rate of this
      # annuity

      k = 1.0 / (1.0 + rate)
      pv = k * (1.0 - k**periods) / (1.0 - k)
      pv * amount
    end
  end
end
