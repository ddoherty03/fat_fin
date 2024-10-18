# frozen_string_literal: true

module FatFin
  # This class represents a stream of payments made at arbitrary dates, not
  # necessarily evenly spaced.
  class CashFlow
    using DateExtension

    DEFAULT_EPS = 0.0000001

    attr_accessor :flow_hash

    def initialize(cash_points = [])
      cash_points = cash_points.to_a
      raise ArgumentError, "All CashFlow components must be CashPoints" unless cash_points.all?(FatFin::CashPoint)

      # Build Hash keyed on CashPoint dates. This will faciliatate merging of
      # one CashFlow into another.
      @flow_hash = {}
      cash_points.each do |cp|
        @flow_hash[cp.date] =
          if @flow_hash[cp.date]
            @flow_hash[cp.date].merge(cp)
          else
            cp
          end
      end
    end

    def precision_of(flt)
      Math.log(flt, 10).abs.round(0)
    end

    # Add a new CashPoint to an existing CashFlow.
    def add_cash_point(cp)
      raise ArgumentError, "CashFlow component must be a CashPoint" unless cp.is_a?(FatFin::CashPoint)

      if flow_hash.key?(cp.date)
        flow_hash[cp.date].merge(cp)
      else
        flow_hash[cp.date] = cp
      end
      self
    end

    # Merge CashPoint or CashFlow into this CashFlow.
    def <<(other)
      case other
      when CashPoint
        add_cash_point(other)
      when CashFlow
        other.cash_points.each do |cp|
          add_cash_point(cp)
        end
      else
        raise ArgumentError, "May only merge CashFlow or CashPoint" unless tval.is_a?(FatFin::CashPoint)
      end
      self
    end

    # Return the array of amounts of the CashPoints
    def amounts
      flow_hash.values.map(&:amount)
    end

    # Return the array of CashPoints
    def cash_points
      flow_hash.values.sort
    end

    # Return the array of the dates in this CashFlow, sorted.
    def dates
      flow_hash.keys.sort
    end

    def first_date
      dates.first
    end

    def last_date
      dates.last
    end

    def years
      return 0.0 if empty?

      (last_date - first_date) / 365.25
    end

    # Return the number of CashPoints in this CashFlow.
    def size
      flow_hash.size
    end

    # Return whether this CashFlow has no CashPoints, i.e., is empty.
    def empty?
      size.zero?
    end

    def sum
      amounts.sum
    end

    def positive_sum
      amounts.select(&:positive?).sum
    end

    def negative_sum
      amounts.select(&:negative?).sum
    end

    # IRR cannot be computed unless the CashFlow has at least one positive and
    # one negative value.  This tests for that.
    def mixed_signs?
      pos, neg = pos_neg_partition
      pos.size >= 1 && neg.size >= 1
    end

    # Return the Period from the first to the last CashPoint in this CashFlow.
    def period
      return if empty?

      Period.new(first_date, last_date)
    end

    # Return a new CashFlow that narrows this CashFlow to the given period.
    # All CashPoints before the beginning of the period are rolled up into a
    # single CashPoint having a date of the beginning of the period and an
    # amount that represents their value_on that date.  All the CashPoints
    # that fall within the period are retained and any CashPoints that are
    # beyond the last date of the period are dropped.
    def within(period, rate: 0.1, freq: 1)
      pre_tvs = []
      within_tvs = []
      cash_points.each do |tv|
        if tv.date < period.first
          pre_tvs << tv
        elsif period.contains?(tv.date)
          within_tvs << tv
        end
      end
      pre_cf = CashFlow.new(pre_tvs)
      first_val = pre_cf.value_on(period.first, rate: rate, freq: freq)
      first_tv = CashPoint.new(first_val, date: period.first)
      CashFlow.new(within_tvs) << first_tv
    end

    # Return the net present value of the CashFlow as of the given date, using
    # the given rate and compunding frequency.
    def value_on(on_date = cash_points.first&.date || Date.today, rate: 0.1, freq: 1)
      cash_points.sum(0.0) { |pmt| pmt.value_on(on_date, rate: rate, freq: freq) }
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
    # example, a CashFlow with all positive or all negative CashPoints will
    # never yeild an NPV of zero.  You can print the progress of the
    # algorithim by setting the verbose: parameter (default false) to true.
    def irr(eps: DEFAULT_EPS, guess: nil, freq: 1, verbose: false)
      return 0.0 if cash_points.empty?
      return Float::NAN unless mixed_signs?

      guess ||= initial_guess

      puts "Newton-Raphson search (eps = #{eps}):"
      puts "-" * 30 if verbose
      try_irr = guess
      recovery_tried = false
      iters = 1
      while (npv = value_on(first_date, rate: try_irr, freq: freq)).abs > eps
        if iters > 100 && !recovery_tried
          puts "Reached 100 iterations: switching to binary search algorithm ... " if verbose
          return birr(eps: eps, freq: freq, verbose: verbose)
        end

        npv_prime = value_on_prime(first_date, rate: try_irr, freq: freq)
        if npv_prime.is_a?(Complex)
          if verbose
            prec = precision_of(eps)
            puts "NPV' turned Complex': switching to binary search algorithm ... " if verbose
            fmt_str = "Iter: %<iters>d, Guess: %<try_irr>4.#{prec}f; " \
              "NPV: %<npv>4.#{prec}f; NPV': %<npv_prime>s\n"
            printf fmt_str, { iters: iters, try_irr: try_irr, npv: npv, npv_prime: "Complex" }
          end
          return birr(eps: eps, freq: freq, verbose: verbose)
        end

        if npv_prime.abs < eps
          puts "Derivative of NPV near zero: switching to binary search algorithm ... "
          return birr(eps: eps, freq: freq, verbose: verbose)
        end
        if verbose
          printf "Iter: %<iters>d, Guess: %<try_irr>4.8f; NPV: %<npv>4.12f; NPV': %<npv_prime>4.12f\n",
                 { iters: iters, try_irr: try_irr, npv: npv, npv_prime: npv_prime }
        end

        if npv.is_a?(Complex) && !recovery_tried
          # If we get a Complex npv, flip the sign of the guess and start
          # over.  But only try this onece.
          try_irr = -guess
          recovery_tried = true
          next
        end

        new_irr = try_irr - (npv / npv_prime)
        if new_irr > 10_000 && guess.abs > 1.0
          try_irr = 0.5
          recovery_tried = true
          next
        end
        break if (new_irr - try_irr).abs <= eps

        try_irr = new_irr
        iters += 1
      end
      puts "-" * 30 if verbose
      try_irr
    end

    # Compute the annual internal rate of return (IRR) for the CashFlow using
    # the a binary search method.  The IRR is that rate that causes the NPV od
    # the CashFlow to equal zero.  In other words, the rate that causes the
    # #value_on the first date in the flow to equal zero.  It assumes a
    # compounding frequency given by freq: parameter (default 1).  The
    # parameter eps: determines how close to zero we have to get (default
    # 0.000001).  The method depends on having two initial guesses, one that
    # yeilds a negative NPV and one that yields a positive NPV.  These guesses
    # can be supplied by supplying a two-element array of Floats with the
    # guess: parameter.  If no initial guesses are supplied, birr attempts to
    # find two suitable guesses by a heuristic.
    #
    # If you get a Float::NAN result, you may have better luck using different
    # initial guesses, but sometimes there is no rate that can produce an NPV
    # of zero.  For example, a CashFlow with all positive or all negative
    # CashPoints will never yeild an NPV of zero.  You can print the progress
    # of the algorithim by setting the verbose: parameter (default false) to
    # true.
    def birr(eps: DEFAULT_EPS, guesses: nil, freq: 1, verbose: false)
      return Float::NAN unless mixed_signs?
      unless guesses.nil? || (guesses.size == 2 && guesses.all?(Numeric))
        raise ArgumentError, "guesses parameter must be an array of two numbers"
      end

      if guesses
        lo_rate, hi_rate = guesses.sort.map(&:to_f)
      else
        lo_rate, hi_rate = lo_hi_guesses(freq: freq)
      end
      return Float::NAN unless lo_rate

      lo_npv = value_on(first_date, rate: lo_rate, freq: freq)
      hi_npv = value_on(first_date, rate: hi_rate, freq: freq)

      iters = 0
      max_iters = 150

      if verbose
        puts "Binary search (eps = #{eps}):"
        puts "-" * 30
        prec = precision_of(eps)
        fmt_str = "Iter: %<iters>d Rate[%<lo>4.#{prec}f, %<hi>4.#{prec}f]; " \
          "NPV[%<lo_npv>4.#{prec}f {} %<hi_npv>4.#{prec}f]\n"
        printf fmt_str, { iters: iters, lo: lo_rate, hi: hi_rate, lo_npv: lo_npv, hi_npv: hi_npv }
      end

      unless lo_npv.signum * hi_npv.signum == -1
        msg = "NPV at lo_guess (#{lo_rate.commas(4)}) and hi_guess #{hi_rate.commas(4)} do not have opposite signs"
        raise ArgumentError, msg
      end

      result = Float::NAN
      while iters < max_iters
        # Calculate the midpoint
        mid_rate = (lo_rate + hi_rate) / 2.0
        mid_npv = value_on(first_date, rate: mid_rate, freq: freq)

        # Check if the NPV at midpoint is close enough to zero
        if mid_npv.abs < eps
          printf "NPV close enough to zero\n" if verbose
          result = mid_rate
          break
        end

        # Decide which subinterval to choose for the next iteration
        if (lo_npv * mid_npv).negative?
          hi_rate = mid_rate
          hi_npv = mid_npv
        else
          lo_rate = mid_rate
          lo_npv = mid_npv
        end
        # if (hi_rate - lo_rate).abs < eps  # && ((((hi_npv - lo_npv) / mid_npv).abs < eps) ¦| mid_npv <= eps))
        #   printf "Rates close enough together\n" if verbose
        #   result = mid_rate
        #   break
        # end

        iters += 1
        if verbose
          # printf "Iter: %<iters>d Rate[%<lo>0.5f, %<hi>0.5f] NPV[%<lo_npv>4.5f {%<mid_npv>4.5f} %<hi_npv>4.5f]\n",
          printf fmt_str, { iters: iters, lo: lo_rate, hi: hi_rate, lo_npv: lo_npv, hi_npv: hi_npv, mid_npv: mid_npv }
        end
      end
      puts "-" * 30 if verbose
      result
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
      mirr = ((fv / pv)**(1 / years)) - 1.0
      if verbose
        puts "FV of Positive Flow at earn rate (#{earn_rate}): #{fv}"
        puts "PV of Negative Flow at borrow rate (#{borrow_rate}): #{pv}"
        puts "Years from first to last flow: #{years}"
        puts "Modified internal rate of return: #{mirr}"
      end
      mirr
    end

    private

    def pos_neg_partition
      pos, neg = cash_points.filter { |pmt| !pmt.amount.zero? }.partition { |pmt| pmt.amount.positive? }
      [CashFlow.new(pos), CashFlow.new(neg)]
    end

    # Return an estimated guess for IRR based on ratio of inflows to outflows
    # over the period of this CashFlow.
    def initial_guess
      total_inflows, total_outflows = pos_neg_partition
      in_sum = total_inflows.sum.to_f
      out_sum = total_outflows.sum.abs.to_f
      return 0.5 if out_sum.zero?

      ((in_sum / out_sum)**(1.0 / years)) - 1.0
    end

    # Look for a low and high guess across which the NPV changes sign
    def lo_hi_guesses(freq: 1)
      # return [-1.0, 1.0]
      # ratio = positive_sum / negative_sum.abs
      # if ratio > 1
      #   [0.0, 1.0]
      # else
      #   [-1.0, 0.0]
      # end

      # try_npv = value_on(first_date, rate: try_rate, freq: freq)
      # hi_npv = value_on(first_date, rate: 0.0, freq: freq)

      lo = -0.05
      hi = 1.0
      lo_npv = value_on(first_date, rate: lo, freq: freq)
      hi_npv = value_on(first_date, rate: hi, freq: freq)

      printf "Looking for binary guesses\n"
      # printf "Iter: %<iters>d Rate[%<lo>0.5f, %<hi>0.5f] NPV[%<lo_npv>4.5f %<hi_npv>4.5f]\n",
      #        iters: iters, lo: lo, hi: hi, lo_npv: lo_npv, hi_npv: hi_npv
      # binding.break
      if (lo_npv.signum * hi_npv.signum).negative?
        # Different signs
        return [lo, hi]
      end

      if hi_npv > 0.0 # lo_npv < 0.0 && hi_npv < 0.0
        # Both negative.  Increase hi until hi_npv positive
        max_iters = 50
        its = 1
        while hi_npv > 0.0 && its <= max_iters
          hi += 0.2
          hi_npv = value_on(first_date, rate: hi, freq: freq)
          printf "Hi Guess Iter: %<iters>d Rate[%<lo>0.5f, %<hi>0.5f] NPV[%<lo_npv>4.5f %<hi_npv>4.5f]\n",
                 iters: its,
lo: lo,
hi: hi,
lo_npv: lo_npv,
hi_npv: hi_npv # if verbose
          its += 1
        end
      end
      if lo_npv < 0.0 # && hi_npv > 0.0
        # Both positive. Decrease lo until lo_npv negative
        max_iters = 50
        its = 1
        while lo_npv < 0.0 && its <= max_iters
          lo -= 0.1
          lo_npv = value_on(first_date, rate: lo, freq: freq)
          printf "Lo Guess Iter: %<iters>d Rate[%<lo>0.5f] NPV[%<lo_npv>4.5f]\n",
                 iters: its,
lo: lo,
lo_npv: lo_npv # if verbose
          its += 1
        end
      end
      # else
      #   # Both zero?  Return them both as guesses.  Do nothing, the initial
      #   # guesses will get returned.
      #   true
      # end
      return if (lo_npv.signum * hi_npv.signum).positive?

      [lo, hi]
    end

    # Return the /derivative/ of the net present value of the CashFlow as of
    # the given date, using the given rate and compunding frequency.
    def value_on_prime(on_date = cash_points.first&.date || Date.today, rate: 0.1, freq: 1)
      cash_points.sum(0.0) { |pmt| pmt.value_on_prime(on_date, rate: rate, freq: freq) }
    end
  end
end
