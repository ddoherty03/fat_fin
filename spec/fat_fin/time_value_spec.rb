# frozen_string_literal: true

module FatFin
  describe TimeValue do
    let(:tv) { TimeValue.new(45_000.33, date: "2022-11-16") }
    let(:fut_tv) { TimeValue.new(55_102.9895856, date: "2025-01-01") }
    let(:eps) { 0.00001 }

    it "initializes a TimeValue" do
      expect(tv.amount).to eq(45_000.33)
      expect(tv.date).to eq(Date.parse("2022-11-16"))
    end

    describe "#value_on" do
      it "computes simple interest with frequency 0" do
        # About 25.5 months after payment, or 2.125 years.  Simple interest over
        # 2.125 periods is (1+0.1 * 2.125) = 1.2125; and 45_000.33 * 1.2125 =
        # 54562.900125
        expect(tv.value_on("2025-01-01", rate: 0.10, freq: 0)).to be_within(eps).of(54_562.900125)
      end

      it "computes future value at any date with default frequency 1" do
        # About 25.5 months after payment, or 2.125 years, or 2.125 compunding
        # periods.  Rate period is 0.1 / 1 = 0.1.  Compunded over 2.125 periods
        # is (1+0.1)^2.125 = 1.22450187921; and 45_000.33 * 1.22450187921 =
        # 55102.9886501
        expect(tv.value_on("2025-01-01", rate: 0.10)).to be_within(eps).of(55_102.9886501)
      end

      it "computes future value at any date with frequency 2" do
        # About 25.5 months after payment, or 4.25 semi-years.  1.05 ^ 4.25 = 1.23042322767;
        # and 45_000.33 * 1.23042322767  = 55369.4512848
        expect(tv.value_on("2025-01-01", rate: 0.10, freq: 2)).to be_within(eps).of(55_369.4512848)
      end

      it "computes future value at any date with frequency 3" do
        # About 25.5 months after payment, or 6.375 third-years.  1.03333 ^ 6.375 = 1.23248828335;
        # and 45_000.33 * 1.23248828335  = 55462.3794719
        expect(tv.value_on("2025-01-01", rate: 0.10, freq: 3)).to be_within(eps).of(55_462.3794719)
      end

      it "computes future value at any date with frequency 4" do
        # About 25.5 months after payment, or 2.125 years, or 8.5 quarters.
        # Rate per quarter is 0.1 /4 = 0.025.  Compunded over 8.5 quarters is
        # (1+.025)^8.5 = 1.23353891766; and 45_000.33 * 1.23353891766
        # = 55509.6583625
        expect(tv.value_on("2025-01-01", rate: 0.10, freq: 4)).to be_within(eps).of(55_509.6583625)
      end

      it "computes future value at any date with frequency 6" do
        # About 25.5 months after payment, or 2.125 years, or 12.75 bi-months.
        # Rate per bi-month is 0.1 / 6 = 0.0166666666667.  Compunded over 12.75
        # bi-months is (1+0.0166666666667)^12.75 = 1.23460193712; and 45_000.33 *
        # 1.23460193712 = 55557.494589
        expect(tv.value_on("2025-01-01", rate: 0.10, freq: 6)).to be_within(eps).of(55_557.494589)
      end

      it "computes future value at any date with continuous compounding " do
        # About 25.5 months after payment, or 2.125 years.  With contiuous
        # compunding at a rate of 0.10, the future value should be e^(0.1*2.125) = 1.23676611357
        # 1.23676611357 * 45_000.33 = 55654.8832435
        expect(tv.value_on("2025-01-01", rate: 0.10, freq: :cont)).to be_within(eps).of(55_654.8832435)
      end

      it "computes discounted value at any date with default frequency 1" do
        # About 25.5 months after payment, or 2.125 years, or 2.125 compunding
        # periods.  Rate period is 0.1 / 1 = 0.1.  Discounted over 2.125 periods
        # is (1+0.1)^2.125 = 1.22450187921; and 55102.9895856 / 1.22450187921 =
        # 45000.330764
        expect(fut_tv.value_on("2022-11-16", rate: 0.10)).to be_within(eps).of(45_000.330764)
      end

      it "computes discounted value at any date with continuous compounding " do
        # About 25.5 months after payment, or 2.125 years.  With contiuous
        # compunding at a rate of 0.10, the future value should be e^(0.1*2.125) = 1.23676611357
        # 1.23676611357 * 45_000.33 = 55654.8832435
        tv1 = TimeValue.new(55_654.8832435, date: "2025-01-01")
        expect(tv1.value_on("2022-11-16", rate: 0.10, freq: :cont)).to be_within(eps).of(45_000.33)
      end

      it "has the same value on the payment date" do
        expect(tv.value_on(tv.date, rate: 0.10)).to be_within(eps).of(tv.amount)
        expect(tv.value_on(tv.date, rate: 0.15, freq: 12)).to be_within(eps).of(tv.amount)
      end
    end

    describe "#cagr" do
      it "computes cagr with default frequency 1" do
        expect(fut_tv.cagr(tv)).to be_within(eps).of(0.10)
      end

      it "computes cagr with frequency 2" do
        expect(fut_tv.cagr(tv, freq: 2)).to be_within(eps).of(0.097617704)
      end

      it "computes cagr with frequency 3" do
        expect(fut_tv.cagr(tv, freq: 3)).to be_within(eps).of(0.09684035)
      end

      it "computes cagr with frequency 4" do
        expect(fut_tv.cagr(tv, freq: 4)).to be_within(eps).of(0.09645476)
      end

      it "computes cagr with frequency 6" do
        expect(fut_tv.cagr(tv, freq: 6)).to be_within(eps).of(0.09607121)
      end

      it "computes cagr with frequency 12" do
        expect(fut_tv.cagr(tv, freq: 12)).to be_within(eps).of(0.09568969)
      end

      it "computes cagr with continuous compunding" do
        expect(fut_tv.cagr(tv, freq: :cont)).to be_within(eps).of(0.09531018)
      end

      it "computes cagr with simple interest, no compunding" do
        expect(fut_tv.cagr(tv, freq: 0)).to be_within(eps).of(0.10564795)
      end
    end
  end
end
