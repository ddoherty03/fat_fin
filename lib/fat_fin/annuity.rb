# frozen_string_literal: true

module FatFin
  class Annuity
    attr_reader :periods, :amount, :freq

    def initialize(periods: 1, amount: 0.0, freq: 1)
      @periods = periods
      @amount = amount
    end

    def to_s
      "Annuity[#{@periods} periods of #{@amount}, compounding #{freq} times per year]"
    end

    def present_value(rate: 0.1)
      # Return present value using rate as the annual discount rate of this
      # annuity

      k = 1.0 / (1.0 + rate)
      pv = k * (1.0 - k**periods) / (1.0 - k)
      pv * amount
    end
  end

  class Annuity2
    attr_reader :periods, :present_value, :future_value, :rate, :payment

    def initialize(periods: nil, present_value: nil, future_value: nil, rate: nil, payment: nil)
      n_nils = [periods, present_value, future_value, rate, payment].select(&:nil?).size
      case n_nils
      when 0
        raise ArgumentError, "At least one of the annuity parameters must be nil"
      when 1
        solve_for =
          if periods.nil?
            :periods
          elsif present_value.nil?
            :present_value
          elsif future_value.nil?
            :future_value
          elsif rate.nil?
            :rate
          else
            :payment
          end
      else
        raise ArgumentError, "No more than one of the annuity parameters may be nil"
      end
    end

    def to_s
      "Annuity[#{@periods} periods of #{@amount}, compounding #{freq} times per year]"
    end
  end
end
