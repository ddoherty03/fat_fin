# frozen_string_literal: true

module FatFin
  # This class represents a stream of payments made at arbitrary dates, not
  # necessarily evenly spaced.
  class CashFlow
    using DateExtension

    def initialize(time_values = [])
      @time_values = time_values.to_a
      return if @time_values.all? { |tv| tv.is_a?(FatFin::TimeValue) }

      raise ArgumentError, "All CashFlow components must be TimeValues"
    end

    # Add a new Payment to an existing CashFlow.
    def add_time_value(tval)
      raise ArgumentError, "CashFlow component must be a TimeValue" unless tval.is_a?(FatFin::TimeValue)

      @time_values << tval
      self
    end

    def <<(tval)
      add_time_value(tval)
    end

    def time_values
      @time_values.sort
    end

    # Return the net present value of the CashFlow as of the given date, using
    # the given rate and compunding frequency.
    def value_on(on_date = time_values.first&.date || Date.today, rate: 0.1, freq: 1)
      time_values.sum(0.0) { |pmt| pmt.value_on(on_date, rate: rate, freq: freq) }
    end

    # Compute the internal rate of return (IRR) for the CashFlow using the
    # Newton-Raphson method and always assuming annual compounding.
    def irr(eps = 0.000001, guess: 0.5, freq: 1, verbose: false)
      return 0.0 if time_values.empty?
      return Float::NAN unless mixed_signs?

      first_date = time_values.first&.date || Date.today
      try_irr = guess
      recovery_tried = false
      iters = 1
      while (npv = value_on(first_date, rate: try_irr, freq: freq)).abs > eps
        return Float::NAN if iters > 100

        if npv.is_a?(Complex) && !recovery_tried
          # If we get a Complex npv, flip the sign of the guess and start
          # over.  But only try this onece.
          try_irr = -guess
          recovery_tried = true
          next
        end

        npv_prime = value_on_prime(first_date, rate: try_irr, freq: freq)
        return Float::NAN if npv_prime.is_a?(Complex)

        new_irr = try_irr - npv / npv_prime
        if new_irr > 10_000 && guess.abs > 1.0
          try_irr = 0.5
          recovery_tried = true
          next
        end
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

    private

    # Return the /derivative/ of the net present value of the CashFlow as of
    # the given date, using the given rate and compunding frequency.
    def value_on_prime(on_date = time_values.first&.date || Date.today, rate: 0.1, freq: 1)
      time_values.sum(0.0) { |pmt| pmt.value_on_prime(on_date, rate: rate, freq: freq) }
    end

    # IRR cannot be computed unless the CashFlow has at least one positive and
    # one negative value.  This tests for that.
    def mixed_signs?
      pos, neg = time_values.filter { |pmt| !pmt.amount.zero? }.partition { |pmt| pmt.amount.positive? }
      pos.size >= 1 && neg.size >= 1
    end
  end
end
