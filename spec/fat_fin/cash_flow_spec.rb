# frozen_string_literal: true

module FatFin
  RSpec.describe CashFlow do
    let!(:cps) do
      all = []
      dt = Date.parse('2022-08-14')
      amt = -10_000
      1.upto(20) do |_k|
        all << CashPoint.new(amt, date: dt)
        amt = [amt + 4_700, 1_000].min
        dt += 1.month
      end
      all
    end
    let!(:flow) do
      flw = CashFlow.new(cps)
      flw.add_cash_point(CashPoint.new(1479.33, date: Date.parse('2024-09-14')))
      flw
    end
    let!(:mt_flow) { CashFlow.new }
    let(:eps) { 0.00001 }

    describe "initialization" do
      it "initializes a CashFlow" do
        expect(flow.cash_points.count).to eq(21)
        expect(flow.cash_points).to all be_a(CashPoint)
      end

      it "initializes an empty CashFlow" do
        expect(mt_flow.cash_points.count).to eq(0)
        expect(mt_flow.value_on(Date.today, rate: 0.05)).to be_zero
      end
    end

    describe "#value_on" do
      it "computes value on a given date" do
        expect(flow.value_on(flow.cash_points.first.date, rate: 0.05)).to be_within(eps).of(1722.37916)
      end
    end

    describe "attribute methods" do
      it '#amounts' do
        expect(flow.amounts).to all be_a(Float)
        expect(mt_flow.amounts).to be_empty
      end

      it "#cash_points" do
        expect(flow.cash_points).to all be_a(CashPoint)
        expect(mt_flow.cash_points).to be_empty
      end

      it "#dates" do
        expect(flow.dates).to all be_a(Date)
        expect(mt_flow.cash_points).to be_empty
      end

      it "#first_date" do
        expect(flow.first_date).to eq(Date.parse('2022-08-14'))
      end

      it "#last_date" do
        expect(flow.last_date).to eq(Date.parse('2024-09-14'))
      end

      it "#years" do
        expect(flow.years).to be_within(eps).of(2.0862422)
        expect(mt_flow.years).to eq(0)
      end

      it "#size" do
        expect(flow.size).to eq(21)
        expect(mt_flow.size).to eq(0)
      end

      it "#empty?" do
        expect(flow).not_to be_empty
        expect(mt_flow).to be_empty
      end

      it '#sum' do
        expect(flow.sum).to be_within(eps).of(2579.33)
        expect(mt_flow.sum).to be_within(eps).of(0)
      end

      it '#positive_sum' do
        expect(flow.positive_sum).to be_within(eps).of(18479.33)
        expect(mt_flow.positive_sum).to be_within(eps).of(0)
      end

      it '#negative_sum' do
        expect(flow.negative_sum).to be_within(eps).of(-15900.00)
        expect(mt_flow.negative_sum).to be_within(eps).of(0)
      end

      it '#mixed_signs?' do
        expect(flow).to be_mixed_signs
        expect(mt_flow).not_to be_mixed_signs
      end

      it "#period" do
        expect(flow.period).to eq(Period.parse_phrase('from 2022-08-14 to 2024-09-14').first)
        expect(mt_flow.period).to be_nil
      end
    end

    describe "#within" do
      it "constructs sub CashFlow within period" do
        pd = Period.parse('2023')
        wflow = flow.within(pd)
        expect(wflow.first_date).to eq(pd.first)
        expect(wflow.size).to eq(13)
        expect(wflow.last_date).to be <= (pd.last)
      end
    end

    describe "IRR" do
      let!(:pos_pmts) do
        all = []
        dt = Date.today - 25.months
        amt = 1_200
        1.upto(20) do |_k|
          all << CashPoint.new(amt, date: dt)
          amt = [amt + 470, 1_000].min
          dt += 1.month
        end
        all
      end
      let!(:pos_flow) do
        CashFlow.new(pos_pmts)
      end
      let!(:neg_flow) do
        CashFlow.new(pos_pmts.map { |pmt| CashPoint.new(-pmt.amount, date: pmt.date) })
      end

      it "computes IRR" do
        expect(flow.irr(eps: eps, verbose: true)).to be_within(eps).of(0.1702)
      end

      it "computes negative IRR" do
        bad_flow = flow << CashPoint.new(-3_000, date: '2024-09-14')
        irr = bad_flow.irr(verbose: true)
        # This expectation value comes from Libreoffice XIRR function on the
        # same data.
        expect(irr).to be_within(eps).of(-0.0342907057)
        irr = bad_flow.irr(eps: eps, guess: -0.5, verbose: true)
        expect(irr).to be_within(eps).of(-0.0342907057)
      end

      it "computes empty Flow IRR" do
        expect(mt_flow.irr(eps: eps)).to be_within(eps).of(0.0)
      end

      it "irr barfs with all positive amounts" do
        expect(pos_flow.irr(eps: eps)).to be(Float::NAN)
      end

      it "barfs with all negative amounts" do
        expect(neg_flow.irr(eps: eps)).to be(Float::NAN)
      end

      describe "README Example" do
        let(:rm_flow) do
          start_date = Date.parse("2022-01-15")
          cps = [
            FatFin::CashPoint.new(-40_000, date: start_date),
            FatFin::CashPoint.new(-5_000, date: start_date + 18.months)
          ]
          flw = FatFin::CashFlow.new(cps)
          # Add additional CashPoints representing the earnings with the << shovel
          # operator
          earn_date = start_date + 1.month
          20.times do |k|
            flw << FatFin::CashPoint.new(2_000, date: earn_date + k.months)
          end

          # Add the salvage value at the end with the add_cash_point method.
          flw.add_cash_point(FatFin::CashPoint.new(15_000, date: earn_date + 21.months))
          flw
        end

        it "does README example" do
          expect(rm_flow.irr(verbose: true)).to be_within(eps).of(0.23407838)
        end

        it "does README example with frequency 0" do
          expect(rm_flow.irr(guess: 0.5, freq: 0, verbose: true)).to be_within(eps).of(0.24332)
          expect(rm_flow.irr(freq: 0, verbose: true)).to be_within(eps).of(0.24332)
        end

        it "computes #within-ed flow IRR" do
          q3 = Period.parse('2022')
          flow3q = flow.within(q3)
          expect(flow3q.irr(verbose: true)).to be_within(eps).of(-0.886497)
          expect(flow3q.mirr(verbose: true)).to be_within(eps).of(-0.8808517)
        end
      end
    end

    describe "BIRR" do
      it "computes BIRR" do
        expect(flow.birr(eps: eps, verbose: true)).to be_within(eps).of(0.1702)
      end

      it "computes negative BIRR" do
        bad_flow = flow << CashPoint.new(-3_000, date: '2024-09-14')
        irr = bad_flow.birr(lo_guess: -0.5, hi_guess: -0.02, verbose: true)
        # This expectation value comes from Libreoffice XIRR function on the
        # same data.
        expect(irr).to be_within(eps).of(-0.0342907057)

        # irr = bad_flow.birr(eps: eps, verbose: true)
        expect(irr).to be_within(eps).of(-0.0342907057)
      end
    end

    describe "MIRR" do
      it "computes MIRR" do
        expect(flow.mirr).to be_within(eps).of(0.1035626)
        expect(flow.mirr(verbose: true)).to be_within(eps).of(0.1035626)
      end

      it "computes MIRR that has a negative IRR" do
        bad_flow = flow << CashPoint.new(-3_000, date: '2024-09-14')
        mirr = bad_flow.mirr(verbose: true)
        expect(mirr).to be_within(eps).of(0.022493)
      end

      it "computes empty Flow MIRR" do
        expect(mt_flow.mirr).to be_within(eps).of(0.0)
      end
    end
  end
end
