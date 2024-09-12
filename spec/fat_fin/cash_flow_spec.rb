require 'fat_fin'

module FatFin
  describe CashFlow do
    let!(:pmts) {
      all = []
      dt = Date.today - 25.months
      amt = -10_000
      1.upto(20) do |k|
        all << Payment.new(amt, date: dt)
        amt = [amt + 4_700, 1_000].min
        dt += 1.month
      end
      all
    }
    let!(:flow) { flw = CashFlow.new(pmts); flw.add_payment(Payment.new(1479.33, date: Date.today)); flw }
    let!(:mt_flow) { CashFlow.new }
    let(:eps) { 0.00001 }

    it 'initializes a CashFlow' do
      expect(flow.payments.count).to eq(21)
      expect(flow.payments).to all be_a(Payment)
    end

    it 'initializes an empty CashFlow' do
      expect(mt_flow.payments.count).to eq(0)
      expect(mt_flow.value_on(Date.today, rate: 0.05)).to be_zero
    end

    it 'computes value on a given date' do
      expect(flow.value_on(flow.payments.first.date, rate: 0.05)).to be_within(eps).of(1722.37916)
    end

    it 'computes IRR' do
      # expect(flow.irr(0.000000000001, verbose: true)).to be_within(eps).of(0.1702)
      expect(flow.irr(eps)).to be_within(eps).of(0.1702)
    end

    it 'computes empty Flow IRR' do
      expect(mt_flow.irr(eps)).to be_within(eps).of(0.0)
    end
  end
end
