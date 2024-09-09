module FatFin
  class Payment
    using DateExtension

    attr_reader :date, :amount

    def initialize(amount = BigDecimal('0.0'), date: Date.today)
      @amount = amount.to_d
      @date = Date.ensure_date(date)
    end

    def to_s
      "Pmt[#{@amount} @ #{@date}]"
    end

    # Return the value of this Payment on a given date, *on_date*, assuming an
    # /annual/ interest rate of *rate*, expressed as a decimal.  Thus, an 8%
    # per-year interest rate would be given as 0.08.  If compounding at a
    # frequency of more than once per year is wanted, include a *freq*
    # parameter that is an even divisor of 12 to indicate how many times per
    # year the interest is to be compounded.  For simple interest, give a
    # frequency, *freq* of 0.  By default, the frequency is 1.
    def value_on(on_date = Date.today, rate: BigDecimal('0.1'), freq: 1)
      rate = rate.to_d
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
  end
end
