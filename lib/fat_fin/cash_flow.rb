module FatFin
  # This class represents a stream of payments made at arbitrary dates, not
  # necessarily evenly spaced.
  class CashFlow
    attr_accessor :payments

    def initialize(payments = [])
      @payments = payments.to_a
      return if @payments.all? { |pmt| pmt.is_a?(FatFin::Payment) }

      raise ArgumentError, "All CashFlow components must be Payments"
    end

    def add_payment(pmt)
      raise ArgumentError, "CashFlow component must be Payment" unless pmt.is_a?(FatFin::Payment)

      @payments << pmt
    end

    def value_on(on_date = payments.first&.date || Date.today, rate: BigDecimal('0.1'), freq: 1)
      payments.sum(BigDecimal('0.0')) { |pmt| pmt.value_on(on_date, rate: rate, freq: freq) }
    end

    def value_on_prime(on_date = payments.first&.date || Date.today, rate: BigDecimal('0.1'), freq: 1)
      payments.sum(BigDecimal('0.0')) { |pmt| pmt.value_on_prime(on_date, rate: rate, freq: freq) }
    end

    def irr(eps = 0.000000001)
      return BigDecimal('0.0') if payments.empty?

      first_date = payments.first&.date || Date.today
      try_irr = 0.5
      iters = 0
      while (npv = value_on(first_date, rate: try_irr, freq: 1)).abs > eps
        break if iters > 1000
        npv_prime = value_on_prime(first_date, rate: try_irr, freq: 1)
        new_irr = try_irr - npv / npv_prime
        # puts "Guess: #{try_irr.round(5)}; NPV: #{npv.round(2)}; NPV': #{npv_prime.round(2)}"
        try_irr = new_irr
        iters += 1
      end
      try_irr
    end
  end
end
