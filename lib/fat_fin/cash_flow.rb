# frozen_string_literal: true

module FatFin
  # This class represents a stream of payments made at arbitrary dates, not
  # necessarily evenly spaced.
  class CashFlow
    using DateExtension

    def initialize(time_values = [])
      time_values = time_values.to_a
      unless time_values.all? { |tv| tv.is_a?(FatFin::TimeValue) }
        raise ArgumentError, "All CashFlow components must be TimeValues"
      end

      # Build Hash keyed on TimeValue dates.
      @time_values = {}
      time_values.each do |tv|
        @time_values[tv.date] =
          if @time_values[tv.date]
            @time_values[tv.date].merge(tv)
          else
            tv
          end
      end
    end

    # Add a new TimeValue to an existing CashFlow.
    def add_time_value(tval)
      raise ArgumentError, "CashFlow component must be a TimeValue" unless tval.is_a?(FatFin::TimeValue)

      if @time_values.keys.include?(tval.date)
        @time_values[tval.date].merge(tval)
      else
        @time_values[tval.date] = tval
      end
      self
    end

    # Add a new TimeValue to an existing CashFlow.
    def <<(tval)
      add_time_value(tval)
    end

    # Return the array of TimeValues
    def time_values
      @time_values.values.sort
    end

    # Return the array of the dates in this CashFlow, sorted.
    def dates
      @time_values.keys.sort
    end

    # Return the number of TimeValues in this CashFlow.
    def size
      time_values.size
    end

    # Return whether this CashFlow has no TimeValues, i.e., is empty.
    def empty?
      size.zero?
    end

    # Return the Period from the first to the last TimeValue in this CashFlow.
    def period
      return nil if empty?

      Period.new(first_date, last_date)
    end

    end

    # Return the net present value of the CashFlow as of the given date, using
    # the given rate and compunding frequency.
    def value_on(on_date = time_values.first&.date || Date.today, rate: 0.1, freq: 1)
      time_values.sum(0.0) { |pmt| pmt.value_on(on_date, rate: rate, freq: freq) }
    end

    # Compute the annual internal rate of return (IRR) for the CashFlow using
    # the Newton-Raphson method.  The IRR is that rate that causes the NPV od
    # the CashFlow to equal zero.  In other words, the rate that causes the
    # #value_on the first date in the flow to equal zero.  It assumes a
    # compounding frequency given by freq: parameter (default 1).  The
    # parameter eps: determines how close to zero we have to get (default
    # 0.000001).  The method depends on using an initial guess, which can be
    # supplied by the guess: parameter (default 0.5).  If you get a Float::NAN
    # result, you may have better luck using a different initial guess, but
    # sometimes there is no rate that can produce an NPV of zero.  For
    # example, a CashFlow with all positive or all negative TimeValues will
    # never yeild an NPV os zero.  You can print the progress of the
    # algorithim by setting the verbose: parameter (default false) to true.
    def irr(eps: 0.000001, guess: 0.5, freq: 1, verbose: false)
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

    # Compute the Modified Internal Rate of Return (MIRR), also called the
    # "Money-Weighted Rate of Return" (MWRR).  This is a much simpler
    # computation than the IRR as it does not require Newton-Raphson.  The
    # idea is to partition the CashFlow into negative (money paid out) and
    # positive (money received) CashFlows.  This method uses one rate that
    # represents the rate at which money can be borrowed in the parameter
    # :borrow_rate and the rate money invested earns (parameter earn_rate:)
    # over the course of the CashFlow.  This simple computes the (1) present
    # value of the outlays, the negative amounts in the CashFlow, to the first
    # date of the CashFlow at the borrow_rate: and (2) the future value of
    # inflows, the positive amounts in the CashFlow, to the last date of the
    # CashFlow at the earn_rate: and takes their ratio (FV/PV).  It the
    # determines the annualized rate of return that would be represented by
    # that outcome.  In computing the PV and FV, you can assume a compounding
    # frequency with the parameter freq: other than the default of 1 per year.
    # You can also have the FV, PV, and result printed to standard out by
    # setting the verbose: parameter (default false) to true.
    def mirr(earn_rate: 0.05, borrow_rate: 0.07, freq: 1, verbose: false)
      pos_flows, neg_flows = pos_neg_partition
      return Float::INFINITY if pos_flows.size.positive? && neg_flows.empty?
      return 0.0 if pos_flows.empty?

      fv = pos_flows.value_on(last_date, rate: earn_rate, freq: freq)
      pv = -neg_flows.value_on(first_date, rate: borrow_rate, freq: freq)
      years = last_date.month_diff(first_date) / 12.0
      mirr = (fv / pv)**(1 / years) - 1.0
      if verbose
        puts "FV of Positive Flow at earn rate (#{earn_rate}): #{fv}"
        puts "PV of Negative Flow at borrow rate (#{borrow_rate}): #{pv}"
        puts "Years from first to last flow: #{years}"
        puts "Modified internal rate of return: #{mirr}"
      end
      mirr
    end

    private

    def first_date
      time_values.first.date
    end

    def last_date
      time_values.last.date
    end

    def pos_neg_partition
      pos, neg = time_values.filter { |pmt| !pmt.amount.zero? }.partition { |pmt| pmt.amount.positive? }
      [CashFlow.new(pos), CashFlow.new(neg)]
    end

    # Return the /derivative/ of the net present value of the CashFlow as of
    # the given date, using the given rate and compunding frequency.
    def value_on_prime(on_date = time_values.first&.date || Date.today, rate: 0.1, freq: 1)
      time_values.sum(0.0) { |pmt| pmt.value_on_prime(on_date, rate: rate, freq: freq) }
    end

    # IRR cannot be computed unless the CashFlow has at least one positive and
    # one negative value.  This tests for that.
    def mixed_signs?
      pos, neg = pos_neg_partition
      pos.size >= 1 && neg.size >= 1
    end
  end
end
