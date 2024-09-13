# frozen_string_literal: true

module FatFin
  describe CashFlow do
    let!(:pmts) do
      all = []
      dt = Date.today - 25.months
      amt = -10_000
      1.upto(20) do |_k|
        all << Payment.new(amt, date: dt)
        amt = [amt + 4_700, 1_000].min
        dt += 1.month
      end
      all
    end
    let!(:flow) do
      flw = CashFlow.new(pmts)
      flw.add_payment(Payment.new(1479.33, date: Date.today))
      flw
    end
    let!(:mt_flow) { CashFlow.new }
    let(:eps) { 0.00001 }

    describe "initialization" do
      it "initializes a CashFlow" do
        expect(flow.payments.count).to eq(21)
        expect(flow.payments).to all be_a(Payment)
      end

      it "initializes an empty CashFlow" do
        expect(mt_flow.payments.count).to eq(0)
        expect(mt_flow.value_on(Date.today, rate: 0.05)).to be_zero
      end
    end

    describe "time value" do
      it "computes value on a given date" do
        expect(flow.value_on(flow.payments.first.date, rate: 0.05)).to be_within(eps).of(1722.37916)
      end
    end

    describe "IRR" do
      let!(:pos_pmts) do
        all = []
        dt = Date.today - 25.months
        amt = 1_200
        1.upto(20) do |_k|
          all << Payment.new(amt, date: dt)
          amt = [amt + 470, 1_000].min
          dt += 1.month
        end
        all
      end
      let!(:pos_flow) do
        CashFlow.new(pos_pmts)
      end
      let!(:neg_flow) do
        CashFlow.new(pos_pmts.map { |pmt| Payment.new(-pmt.amount, date: pmt.date) })
      end

      it "computes IRR" do
        # expect(flow.irr(0.000000000001, verbose: true)).to be_within(eps).of(0.1702)
        expect(flow.irr(eps)).to be_within(eps).of(0.1702)
      end

      it "computes negative IRR" do
        bad_flow = flow << Payment.new(-3_000, date: Date.today)
        irr = bad_flow.irr(verbose: true)
        # This expectation value comes from Libreoffice XIRR function on the
        # same data.
        expect(irr).to be_within(eps).of(-0.0342907057)
        irr = bad_flow.irr(guess: -0.5, verbose: true)
        expect(irr).to be_within(eps).of(-0.0342907057)
      end

      it "computes empty Flow IRR" do
        expect(mt_flow.irr(eps)).to be_within(eps).of(0.0)
      end

      it "barfs with all positive amounts" do
        expect(pos_flow.irr(eps)).to be(Float::NAN)
      end

      it "barfs with all negative amounts" do
        expect(neg_flow.irr(eps)).to be(Float::NAN)
      end
    end
  end
end
