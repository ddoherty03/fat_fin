require 'fat_fin'

module FatFin
  describe Payment do
    let(:pmt) { Payment.new(45_000.33, date: '2022-11-16') }
    let(:fut_pmt) { Payment.new(55102.9895856, date: '2025-01-01') }
    let(:eps) { 0.00001 }

    it 'initializes a Payment' do
      expect(pmt.amount).to eq(BigDecimal('45000.33'))
      expect(pmt.date).to eq(Date.parse('2022-11-16'))
    end

    it 'computes simple interest with frequency 0' do
      # About 25.5 months after payment, or 2.125 years.  Simple interest over
      # 2.125 periods is (1+0.1 * 2.125) = 1.2125; and 45_000.33 * 1.2125 =
      # 54562.900125
      expect(pmt.value_on('2025-01-01', rate: 0.10, freq: 0)).to be_within(eps).of(54562.900125)
    end

    it 'computes future value at any date with default frequency 1' do
      # About 25.5 months after payment, or 2.125 years, or 2.125 compunding
      # periods.  Rate period is 0.1 / 1 = 0.1.  Compunded over 2.125 periods
      # is (1+0.1)^2.125 = 1.22450187921; and 45_000.33 * 1.22450187921 =
      # 55102.9886501
      expect(pmt.value_on('2025-01-01', rate: 0.10)).to be_within(eps).of(55102.9886501)
    end

    it 'computes future value at any date with frequency 2' do
      # About 25.5 months after payment, or 4.25 semi-years.  1.05 ^ 4.25 = 1.23042322767;
      # and 45_000.33 * 1.23042322767  = 55369.4512848
      expect(pmt.value_on('2025-01-01', rate: 0.10, freq: 2)).to be_within(eps).of(55369.4512848)
    end

    it 'computes future value at any date with frequency 3' do
      # About 25.5 months after payment, or 6.375 third-years.  1.03333 ^ 6.375 = 1.23248828335;
      # and 45_000.33 * 1.23248828335  = 55462.3794719
      expect(pmt.value_on('2025-01-01', rate: 0.10, freq: 3)).to be_within(eps).of(55462.3794719)
    end

    it 'computes future value at any date with frequency 4' do
      # About 25.5 months after payment, or 2.125 years, or 8.5 quarters.
      # Rate per quarter is 0.1 /4 = 0.025.  Compunded over 8.5 quarters is
      # (1+.025)^8.5 = 1.23353891766; and 45_000.33 * 1.23353891766
      # = 55509.6583625
      expect(pmt.value_on('2025-01-01', rate: 0.10, freq: 4)).to be_within(eps).of(55509.6583625)
    end

    it 'computes future value at any date with frequency 6' do
      # About 25.5 months after payment, or 2.125 years, or 12.75 bi-months.
      # Rate per bi-month is 0.1 / 6 = 0.0166666666667.  Compunded over 12.75
      # bi-months is (1+0.0166666666667)^12.75 = 1.23460193712; and 45_000.33 *
      # 1.23460193712 = 55557.494589
      expect(pmt.value_on('2025-01-01', rate: 0.10, freq: 6)).to be_within(eps).of(55557.494589)
    end

    it 'computes past value at any date with default frequency 1' do
      # About 25.5 months after payment, or 2.125 years, or 2.125 compunding
      # periods.  Rate period is 0.1 / 1 = 0.1.  Discounted over 2.125 periods
      # is (1+0.1)^2.125 = 1.22450187921; and 55102.9895856 / 1.22450187921 =
      # 45000.330764
      expect(fut_pmt.value_on('2022-11-16', rate: 0.10)).to be_within(eps).of(45000.330764)
    end

    it 'has the same value on the payment date' do
      expect(pmt.value_on(pmt.date, rate: 0.10)).to be_within(eps).of(pmt.amount)
      expect(pmt.value_on(pmt.date, rate: 0.15, freq: 12)).to be_within(eps).of(pmt.amount)
    end
  end
end
