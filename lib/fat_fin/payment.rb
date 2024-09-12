module FatFin
  class Payment
    using DateExtension

    attr_reader :date, :amount

    def initialize(amount = 0.0, date: Date.today)
      @amount = amount
      @date = Date.ensure_date(date)
    end

    def to_s
      "Pmt[#{@amount} @ #{@date}]"
    end

    # Return the net present value (NPV) of this Payment on a given date,
    # *on_date*, assuming an /annual/ interest rate of *rate*, expressed as a
    # decimal.  Thus, an 8% per-year interest rate would be given as 0.08.  If
    # compounding at a frequency of more than once per year is wanted, include
    # a *freq* parameter that is an even divisor of 12 to indicate how many
    # times per year the interest is to be compounded.  For simple interest,
    # give a frequency, *freq* of 0.  By default, the frequency is 1.  This
    # works equally well for computing a future value of this Payment if the
    # on_date is later than the Payment's date.'
    def value_on(on_date = Date.today, rate: 0.1, freq: 1)
      on_date = Date.ensure_date(on_date)

      # Check frq for sanity
      unless [0, 1, 2, 3, 4, 6, 12].include?(freq)
        raise ArgumentError, "Compounding frequency (#{freq}) must be a divisor of 12."
      end

      # Number of years between Payment's date and the date on which discouted
      # value is being measured.
      years = on_date.month_diff(date) / 12.0

      # Now the calculation
      if freq.zero?
        # Simple interest, just rate times number of years
        if years >= 0
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

    # Return the /derivative/ of the net present value of the Payment as of
    # the given date, using the given rate and compunding frequency.
    def value_on_prime(on_date = Date.today, rate: 0.1, freq: 1)
      # rate = rate
      on_date = Date.ensure_date(on_date)

      # Check frq for sanity
      unless [1, 2, 3, 4, 6, 12].include?(freq)
        raise ArgumentError, "Compounding frequency (#{freq}) must be a divisor of 12."
      end

      # Number of years between Payment's date and the date on which discouted
      # value is being measured.
      years = on_date.month_diff(date) / 12.0

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
