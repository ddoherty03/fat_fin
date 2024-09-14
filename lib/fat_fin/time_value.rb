# frozen_string_literal: true

module FatFin
  # This class represents an amount of money on a given date.  If the amount
  # is negative, the amount was paid out, if positive, it was paid in.  This
  # class provides a method for computing the time-value of the amount as of
  # some given date at a given rate and a given compunding frequency.  It can
  # be used for both discounting back in time and compunding forward in time.
  class TimeValue
    using DateExtension

    attr_reader :date, :amount

    def initialize(amount, date: Date.today)
      @amount = amount
      @date = Date.ensure_date(date)
    end

    include Comparable

    def <=>(other)
      date <=> other.date
    end

    def to_s
      "TV[#{@amount} @ #{@date}]"
    end

    # Check frq for sanity.  It must be an even divisior of 12 or the symbol
    # :cont to indicate continuos compounding.
    def valid_freq?(frq)
      [0, 1, 2, 3, 4, 6, 12, :cont].include?(frq)
    end

    # Return the net present value (NPV) of this TimeValue on a given date,
    # *on_date*, assuming an /annual/ interest rate of *rate*, expressed as a
    # decimal.  Thus, an 8% per-year interest rate would be given as 0.08.  If
    # compounding at a frequency of more than once per year is wanted, include
    # a *freq* parameter that is an even divisor of 12 to indicate how many
    # times per year the interest is to be compounded.  For simple interest,
    # give a frequency, *freq* of 0.  By default, the frequency is 1.  This
    # works equally well for computing a future value of this TimeValue if the
    # on_date is later than the TimeValue's date.'
    def value_on(on_date = date || Date.today, rate: 0.1, freq: 1)
      on_date = Date.ensure_date(on_date)

      raise ArgumentError, "Frequency (#{freq}) must be a divisor of 12 or :cont." unless valid_freq?(freq)

      # Number of years between TimeValue's date and the date on which discouted
      # value is being measured.
      years = on_date.month_diff(date) / 12.0

      # Now the calculation
      if freq == :cont
        # Continuous compounding
        amount * Math.exp(rate * years)
      elsif freq.zero?
        # Simple interest, just rate times number of years
        if years.positive?
          amount * (1.0 + (rate * years))
        else
          amount / (1.0 + (rate * -years))
        end
      else
        # Compund interest, accumulate interest freq times per year
        periods = years * freq
        # Rate per period
        rate_per_period = rate / freq
        amount * ((1.0 + rate_per_period)**periods)
      end
    end

    # Compute the "compound annual growth rate" that would have been required
    # to arrive at this TimeValue from the given from_tv, where the rate is
    # compounded freq times per year.
    def cagr(from_tv, freq: 1)
      raise ArgumentError, "Frequency (#{freq}) must be a divisor of 12 or :cont." unless valid_freq?(freq)

      years = date.month_diff(from_tv.date) / 12.0
      if freq == :cont
        Math.log(amount / from_tv.amount) / years
      elsif freq.zero?
        ((amount / from_tv.amount) - 1.0) / years
      else
        periods = freq * years
        freq * ((amount / from_tv.amount)**(1 / periods) - 1.0)
      end
    end

    # Return the /derivative/ of the net present value of the TimeValue as of
    # the given date, using the given rate and compunding frequency.
    def value_on_prime(on_date = Date.today, rate: 0.1, freq: 1)
      # rate = rate
      on_date = Date.ensure_date(on_date)
      raise ArgumentError, "Frequency (#{freq}) must be a divisor of 12 or :cont." unless valid_freq?(freq)

      # Number of years between TimeValue's date and the date on which
      # discouted value is being measured.
      years = on_date.month_diff(date) / 12.0

      if freq == :cont
        # Continuous compounding
        amount * years * Math.exp(rate * years)
      elsif freq.zero?
        # Simple interest
        if years.positive?
          amount * years
        else
          -(amount * years) / (1 + rate * years)**2
        end
      else
        # Compund interest, accumulate interest freq times per year
        periods = years * freq
        # Rate per period
        rate_per_period = rate / freq

        # This is the derivative of the value_on (NPV) of amount with respect to
        # rate.  It will be used in improving guesses using the Newton-Raphson
        # interation in the IRR calculation.
        ((periods - 1) * amount) * (1 + rate_per_period)**(periods - 1)
      end
    end
  end
end
