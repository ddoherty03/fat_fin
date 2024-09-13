# frozen_string_literal: true

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

    # Add a new Payment to an existing CashFlow.
    def add_payment(pmt)
      raise ArgumentError, "CashFlow component must be Payment" unless pmt.is_a?(FatFin::Payment)

      @payments << pmt
      self
    end

    def <<(pmt)
      add_payment(pmt)
    end

    # Return the net present value of the CashFlow as of the given date, using
    # the given rate and compunding frequency.
    def value_on(on_date = payments.first&.date || Date.today, rate: 0.1, freq: 1)
      payments.sum(0.0) { |pmt| pmt.value_on(on_date, rate: rate, freq: freq) }
    end

    # Return the /derivative/ of the net present value of the CashFlow as of
    # the given date, using the given rate and compunding frequency.
    def value_on_prime(on_date = payments.first&.date || Date.today, rate: 0.1, freq: 1)
      payments.sum(0.0) { |pmt| pmt.value_on_prime(on_date, rate: rate, freq: freq) }
    end

    # IRR cannot be computed unless the CashFlow has at least one positive and
    # one negative value.  This tests for that.
    def mixed_signs?
      pos, neg = payments.filter { |pmt| !pmt.amount.zero? }.partition { |pmt| pmt.amount.positive? }
      pos.size >= 1 && neg.size >= 1
    end

    # Compute the internal rate of return (IRR) for the CashFlow using the
    # Newton-Raphson method and always assuming annual compounding.
    def irr(eps = 0.000001, guess: 0.5, verbose: false)
      return 0.0 if payments.empty?
      return Float::NAN unless mixed_signs?

      first_date = payments.first&.date || Date.today
      try_irr = guess
      sign_flipped = false
      iters = 1
      while (npv = value_on(first_date, rate: try_irr, freq: 1)).abs > eps
        return Float::NAN if iters > 100

        if npv.is_a?(Complex) && !sign_flipped
          # If we get a Complex npv, flip the sign of the guess and start
          # over.  But only try this onece.
          try_irr = -guess
          sign_flipped = true
          next
        end

        npv_prime = value_on_prime(first_date, rate: try_irr, freq: 1)
        return Float::NAN if npv_prime.is_a?(Complex)

        new_irr = try_irr - npv / npv_prime
        if verbose
          printf "Iter: %<iters>d, Guess: %<try_irr>4.8f; NPV: %<npv>4.12f; NPV': %<npv_prime>4.12f\n",
                 { iters: iters, try_irr: try_irr, npv: npv, npv_prime: npv_prime }
        end
        break if (new_irr - try_irr).abs <= eps

        try_irr = new_irr
        iters += 1
      end
      puts "--------------------" if verbose
      try_irr
    end
  end
end
