# frozen_string_literal: true

module FatFin
  class Bond
    attr_reader :maturity, :coupon, :term, :issue_date, :face, :freq, :eom

    def initialize(args = {})
      # Compute @maturity, @issue_date, and @term
      # At least one must be defined
      @maturity = args[:maturity] ? Date.ensure(args[:maturity]) : nil
      @issue_date = args[:issue_date] ? Date.ensure(args[:issue_date]) : nil
      @term = args[:term]&.to_i

      # The following is a rather tedious walk through all the
      # possibilites of which of the three are defined.
      if args[:issue].nil? && args[:term].nil? && args[:maturity].nil?
        raise ArgumentError,
              "Bond.new must supply at least maturity: parameter
                (assumes 30-year term) or supply two
                of maturity:, term:, and issue:"
      elsif args[:maturity] && (args[:issue].nil? && args[:term].nil?)
        # Maturity defined, compute term and issue
        @term = 30
        @issue_date = Date.new(@maturity.year - @term,
                               @maturity.month, @maturity.day)
      elsif args[:issue] && (args[:maturity].nil? && args[:term].nil?)
        # Issue defined, compute maturity and term
        @term = 30
        @maturity = Date.new(@issue_date.year + @term,
                             @issue_date.month, @issue_date.day)
      elsif args[:term] && (args[:maturity].nil? && args[:issue].nil?)
        # Term defined, compute maturity and issue
        # Assume issue is today
        @term = args[:term].to_i
        @issue_date = Date.today
        @maturity = Date.new(@issue_date.year + @term,
                             @issue_date.month, @issue_date.day)
      elsif (args[:maturity] && args[:term]) && !args[:issue]
        # Maturity and term defined, compute issue
        @issue_date = Date.new(@maturity.year - @term,
                               @maturity.month, @maturity.day)
      elsif (args[:issue] && args[:term]) && !args[:maturity]
        # Issue and term defined, compute maturity
        @maturity = Date.new(@issue_date.year + @term,
                             @issue_date.month, @issue_date.day)

      elsif (args[:issue] && args[:maturity]) && !args[:term]
        # Issue and maturity defined, compute term
        if @maturity.month == @issue_date.month &&
           @maturity.day == @issue_date.day
          # Make @term and integer if month and day are the same
          @term = @maturity.year - @issue_date.year
        else
          # Else, punt
          @term = (@maturity - @issue_date) / 365.25
        end
      elsif args[:issue] && args[:maturity] && args[:term]
        # All three defined
        nil
      else
        # None defined
        raise(ArgumentError,
              'Bond.new must define at least one of :maturity, :issue, or :term.')
      end
      # Now check @term, @maturity, and @issue_date for sanity
      unless @maturity > @issue_date
        raise(ArgumentError,
              "Bond maturity #{@maturity} must be later than issue #{@issue_date}.")
      end
      unless @term > 0 && @term <= 100
        raise(ArgumentError,
              "Bond term (#{@term}) not credible.  Use life of Bond in years.")
      end

      #################################################
      # Coupon
      if args[:coupon] < 0.0 || args[:coupon] > 1.0
        raise(ArgumentError,
              'Nonsense coupon rate (#{args[:coupon]}).  Use decimals, not percentages.')
      end
      @coupon = args[:coupon]

      # Face
      args[:face] = args[:face] || 1000.0
      if args[:face] <= 0
        raise(ArgumentError, "Face or bond negative (#{args[:face]}.")
      end
      @face = args[:face]

      # Frequency
      args[:frequency] = args[:frequency] || 2
      unless [1, 2, 3, 4, 6, 12].include?(args[:frequency])
        raise(ArgumentError,
              "Coupon frequency (#{args[:frequency]}) not a divisor of 12.  Suspect.")
      end
      @freq = args[:frequency]

      # Eom
      # eom is true only if coupons are always paid on the last day of the
      # month.  Normally, in the US, bonds pay interest on a fixed day of
      # the month, e.g., the 1st or the 15th, and eom is false for these.
      # Its effect is to modify the day-count convention.
      # See Bond#factor below.
      args[:eom] = args[:eom] || false
      @eom = args[:eom]
    end

    def to_s
      "Bond[#{face}, Due #{maturity}, Coup #{coupon}, #{freq} per yr, Iss #{issue_date}.]"
    end

    def price(yld: 100.0, settle_date: issue_date, convention: 0)
      # Check args for sanity
      if yld < 0.0 || yld > 1.0
        raise ArgumentError,
              "Nonsense yield (#{yld}).  Use decimals, not percentages."
      end

      settle_date = Date.ensure(settle_date)
      if settle_date > maturity
        raise ArgumentError,
              "Settlement date #{settle_date} later than maturity date #{maturity}."
      end

      # Convention for how interest is calculated between interest
      # payment dates.  See factor() and coupon_factor() below.
      # 0 -- US (NASD) 30/360 (default)
      # 1 -- Actual/actual
      # 2 -- Actual/360
      # 3 -- Actual/365
      # 4 -- European 30/360
      # See the details in the Bond#factor function below
      unless [0, 1, 2, 3, 4].include?(convention)
        raise(ArgumentError, 'Day count convention must be 0, 1, 2, 3, or 4.')
      end

      # PV of coupons paid after first coupon date
      # Yield per period, discount rate
      r = yld / freq
      ann_coupon = face * coupon
      coupon_pmt = ann_coupon / freq
      nxt_coup_date = next_coupon_date(settle_date)
      num_coupons = maturity.month_diff(nxt_coup_date).to_int / (12 / freq)
      pv_coup = Annuity.new(periods: num_coupons, amount: coupon_pmt)
                  .present_value(rate: r)
      # Add the next coupon
      pv_coup += coupon_pmt
      # Now discount it as a point payment back to settlement date
      pv_coup =
        CashFlowPoint.new(amount: pv_coup, payout_date: nxt_coup_date)
          .value_on(date: settle_date, rate: yld, freq: 0)

      # PV factor for face at maturity
      # If there are $N coupons after settlement, there are only $N-1 *periods*,
      # so discount the face back this number of periods to get PV to the
      # next coupon date.
      pv_face =
        CashFlowPoint.new(amount: face, payout_date: maturity)
          .value_on(date: nxt_coup_date, rate: yld, freq: freq)
      # Then discount as a point payment back to settlement date.
      pv_face =
        CashFlowPoint.new(amount: pv_face,
                          payout_date: nxt_coup_date)
          .value_on(date: settle_date, rate: yld, freq: 0)

      # Portion of the first coupon that belongs to seller of the bond
      f = factor(settle_date, convention)
      uc = ann_coupon * f

      # PV of total bond
      pv_coup + pv_face - uc
    end

    # Return the next coupon date *after* d
    def next_coupon_date(d)
      mpp = 12 / freq
      next_coup_date = d.dup + 1
      # Step forward by days until we hit the day of maturity
      next_coup_date += 1 while next_coup_date.day != maturity.day
      # Step forward by months until we hit a coupon month
      until maturity.month_diff(next_coup_date) % mpp == 0
        next_coup_date = next_coup_date >> 1
      end
      next_coup_date
    end

    # Return the prior coupon date *on or before* d
    def prior_coupon_date(d)
      mpp = 12 / freq
      next_coupon_date(d) << mpp
    end

    def yld(price: face, settle_date: maturity, convention: 0, verbose: false)
      # Argument sanity
      if price < 0
        raise ArgumentError, "Negative price (#{price})."
      end
      settle_date = Date.ensure(settle_date)

      unless [0, 1, 2, 3, 4].include?(convention)
        raise ArgumentError, 'Day count convention must be 0, 1, 2, 3, or 4.'
      end

      # Use binary search to find yield that produces a bond price
      # equal to $price, within the desired toleration, expressed
      # as the number of decimal places accuracy.
      places = 7
      mid = low = 0.0
      high = 1.00

      # Loop until the computed price is within $places
      # of the given $price
      max_iter = 50
      iterations = 0
      until low.nearly?(high, places) || iterations >= max_iter
        iterations += 1
        mid = (low + high) / 2.0
        computed_price = price(yld: mid, settle_date: settle_date,
                               convention: convention)
        if verbose
          printf("Iter [%02d]: yld [%0.*f, <%0.*f>, %0.*f]; price [%0*.*f]; target [%0*.*f].\n",
                 iterations, places, low, places, mid, places, high, places + 4,
                 places, computed_price, places + 4, places, price)
        end
        if computed_price > price
          low = mid
        else
          high = mid
        end
      end
      mid
    end

    def macaulay_duration(yld: 100.0, settle_date: maturity, convention: 0,
                          verbose: false)
      # Return the "Macaulay duration" of a bond, which is
      # calculated as the weighted average of each cash
      # payment, each weighted by the number of years to maturity
      # and discounted back to the (settlement) date, which is
      # the date as of which the duration is being measured.

      settle_date = Date.ensure(settle_date)

      unless [0, 1, 2, 3, 4].include?(convention)
        raise ArgumentError, 'Day count convention must be 0, 1, 2, 3, or 4.'
      end

      # For a zero-coupon bond, the duration is simply the number
      # of years to maturity since the sole payment occurs at
      # maturity.  Deal with this simple case specially.
      return months_diff(maturity, settle_date) / 12 if coupon == 0.0

      if verbose
        puts "\nMacaulay Duration:"
        puts "Settlement: #{settle_date}"
        puts "Maturity date: #{maturity}"
        puts "Face Value: #{face}"
        puts "Coupon Rate: #{coupon}"
        puts "Yield: #{yld}"
        puts "Frequency: #{freq}"
      end

      # Yield per period, discount rate
      r = yld / freq

      # Coupon amount
      coupon_pmt = (coupon / freq) * face

      # Compute moments of coupons
      moment = 0
      cdate = next_coupon_date(settle_date)
      while cdate <= maturity
        ytc = cdate.month_diff(settle_date) / 12.0
        cf_coup = CashFlowPoint.new(amount: coupon_pmt, payout_date: cdate)
        pv_coup = cf_coup.value_on(date: settle_date, rate: yld, freq: freq)
        moment += ytc * pv_coup
        if verbose
          puts "Coup: #{cdate}; Amt: #{coupon_pmt}: PV: #{pv_coup}; Yrs: #{ytc}"
        end
        cdate = next_coupon_date(cdate)
      end

      # Add moment of face
      ytm = maturity.month_diff(settle_date) / 12.0
      pvm = CashFlowPoint.new(amount: face, payout_date: maturity)
              .value_on(date: settle_date, rate: yld, freq: freq)
      moment += ytm * pvm
      if verbose
        puts "Maturity on #{maturity}: Amount; face: PV: #{pvm}; Yrs: #{ytm}"
        puts "Computed moment is #{moment}"
      end

      # Duration is ratio of moments to price
      mprice = price(yld: yld, settle_date: settle_date, convention: convention)
      puts "Computed price is #{mprice}" if verbose

      # Debug
      if verbose
        puts "Per period yld: #{r}"
        puts "Per period coupon payment: \$#{coupon_pmt}"
        puts "The Macaulay duration is #{moment / mprice}\n"
      end

      moment / mprice
    end

    # Return the "Modified duration" of a bond, which is calculated as the
    # Macaulay duration divided by (1 + $yld/$freq).
    def modified_duration(yld: 100.0, settle_date: Date.today, convention: 0,
                          verbose: false)
      settle_date = Date.ensure(settle_date)

      unless [0, 1, 2, 3, 4].include?(convention)
        raise ArgumentError, 'Day count convention must be 0, 1, 2, 3, or 4.'
      end

      macd = macaulay_duration(yld: yld, settle_date: settle_date,
                               convention: convention, verbose: verbose)
      macd / (1 + yld / freq)
    end

    def factor(date2, conv = 0)
      # Returns fraction of *annual* coupon that has been
      # accrued by date2 for this bond, following the day-count
      # convention, conv.

      # Return the fraction of the year that has elapsed on
      # date2, typically the settlement date.  date1 is the
      # date on which the period begins, usually the prior
      # coupon date date2 is the date of payment or settlement
      # date date3 is the date on which the period ends,
      # usually the next coupon date Source: Wikipedia "Day
      # count conventions"
      #
      # Note: date3 is not used in any of the conventions programmed for
      # here, but it may be used in other conventions.  See the link
      # above for where it might apply.

      date1 = prior_coupon_date(date2)
      # date3 = next_coupon_date(date2)

      # Convention for how interest is calculated between
      # interest payment dates.  This has to do with the
      # fraction by which the annual coupon is multiplied to
      # pay for a partial period.  The numerator is the number
      # of days that have elapsed; The demoniator is the
      # number of days in the entire year.  These
      # involve assumptions about the number of days in the
      # months that fall within the partial period.  They will
      # assume either that every month consists of 30 days,
      # even if the particular period in which the payment
      # occurs contains February, July, and August, or they
      # will take into account the actual number of days in
      # the particular period.

      # comv =
      # 0 -- US (NASD) 30/360 (default)
      # 1 -- Actual/actual
      # 2 -- Actual/360
      # 3 -- Actual/365
      # 4 -- European 30/360

      # The following are extracted from the dates for the
      # 30/360 methods (0 and 4)
      d1 = date1.day
      d2 = date2.day
      # d3 = date3.day
      m1 = date1.month
      m2 = date2.month
      # m3 = date3.month
      y1 = date1.year
      y2 = date2.year
      # y3 = date3.year

      if conv == 0
        #############################################################
        # From  www.eclipsesoftware.biz/DayCountConventions.html#x3_01a
        #############################################################
        # 3.01a - 30U/360
        # The adjustment to Date1 and Date2:
        #     * If security is EOM and (d1 = last-day-of-February) and (d2 = last-day-of-February), then change d2 to 30.
        #     * If security is EOM and (d1 = last-day-of-February), then change d1 to 30.
        #     * If d2 = 31 and d1 is 30 or 31, then change d2 to 30.
        #     * If d1 = 31, then change d1 to 30.
        # This is the convention in the U.S. for corporate, municipal, and some US Agency bonds.
        # This convention is referred to as:
        # Term  Sources
        # 30/360  [SIFMA_SSCM]
        # 30U/360 [SWX_AI]
        # US  [SWX_AI]
        if eom && date1.last_of_feb? && date2.last_of_feb?
          d2 = 30
        end
        if eom && date1.last_of_feb?
          d1 = 30
        end
        if d2 == 31 && (d1 == 30 || d1 == 31)
          d2 = 30
        end
        if d1 == 31
          d1 = 30
        end
        num = 360.0 * (y2 - y1) + 30.0 * (m2 - m1) + (d2 - d1)
        den = 360.0
        fact = (num / den)
      elsif conv == 1
        # Actual Conventions

        # This category of conventions uses the actual number
        # of calendar days in the accrual period. The
        # differences come in the value of Den.

        # N is simply the number of days between Date1 and
        # Date2. For example, the number of days between
        # 2-Nov-2007 and 15-Nov-2007 is 13. Just
        # subtract. This is notated as JulianDays(Date1,
        # Date2).

        # Actual/Actual This convention splits the accrual
        # period into that portion in a leap year and that in
        # a non-leap year. You include the first date in the
        # period and exclude the ending one.
        #
        # The calculation is:
        #     * Fact = ( {Nnl in non-leap year / 365} + {Nly in leap year / 366} )
        # Example
        # Date  Value
        # Date1 15-Dec-2007
        # Date2 10-Jan-2008
        #
        # This results in the values:
        # Term  Calculation Value
        # Nnl JulianDays(15-Dec-2007, 1-Jan-2008) 17
        # Nly JulianDays(1-Jan-2008, 10-Jan-2008) 9
        # Fact  ( {17 / 365} + {9 / 366} )  0.07116551
        if date1.is_leap? == date2.is_leap?
          # Both date1 and date2 are in same kind of year
          num = (date2 - date1).to_f
          den = 365.0
          den = 366.0 if date1.is_leap?
          fact = (num / den)
        else
          # One is in a leap, the other not
          num1 = (Date.new(date2.year, 1, 1) - date1).to_f
          den1 = 365.0
          den1 = 366.0 if date1.is_leap?
          num2 = (date2 - Date.new(date2.year, 1, 1)).to_f
          den2 = 365.0
          den2 = 366.0 if date2.is_leap?
          fact = (num1.to_f / den1.to_f) + (num2.to_f / den2)
        end
      elsif conv == 2
        # A.04 - Act/360
        # Den:
        #     * 360

        # This results in the calculation:
        # AI = CR * (N / 360).
        # This convention is referred to as:
        #
        # Term  Sources
        # Actual/360  [ISDA_4.16_2006], [ISDA_4.16_2000], [SIFMA_SSCM],
        #             [SIA_SSCM], [SWX_AI], [EBF_MA]
        # Act/360 [ISDA_4.16_2006], [ISDA_4.16_2000]
        # A/360 [ISDA_4.16_2006]
        # French  [SWX_AI]
        num = (date2 - date1).to_f
        den = 360.0
        fact = num / den
      elsif conv == 3
        # A.03 - Act/365 (Fixed)
        # Den:
        #     * 365
        # This results in the calculation:
        # AI = CR * (N / 365).
        num = (date2 - date1).to_f
        den = 365.0
        fact = num / den
      elsif conv == 4
        # 3.03 - 30E/360 ISDA
        # The adjustment to Date1 and Date2:
        #     * If d1 = last day of the month, then change d1 to 30.
        #     * If d2 = last day of the month, then change d2 to 30.
        # However, do not make this adjustment if Date2 = MatDt and d2 = February.

        # The d2 qualification for February is often omitted
        # when this convention is discussed. We believe this
        # is an oversight, not a variant.

        # This convention is referred to as:
        # Term  Sources
        # 30E/360 (ISDA)  [ISDA_4.16_2006]
        # 30E/360 [ISDA_4.16_2000]
        # Eurobond Basis  [ISDA_4.16_2000]
        # German  [SWX_AI]
        # German Master [EBF_MA]
        # 360/360 [EBF_MA]
        unless date2 == maturity && date2.month == 2
          if date1.last_of_month?
            d1 = 30.0
          end
          if date2.last_of_month?
            d2 = 30.0
          end
        end
        num = 360.0 * (y2 - y1) + 30.0 * (m2 - m1) + (d2 - d1)
        den = 360.0
        fact = num / den
      end
      fact
    end
  end
end
