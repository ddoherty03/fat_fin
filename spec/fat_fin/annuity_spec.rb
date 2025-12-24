# frozen_string_literal: true

module FatFin
  RSpec.describe Annuity do
    let(:an) { Annuity.new(periods: 28, amount: 1.0) }
    let(:eps) { 0.001 }

    it '#present_value' do
      expect(an.present_value(rate: 0.01)).to be_within(eps).of(24.31644316)
      expect(an.present_value(rate: 0.02)).to be_within(eps).of(21.28127236)
      expect(an.present_value(rate: 0.03)).to be_within(eps).of(18.76410823)
      expect(an.present_value(rate: 0.04)).to be_within(eps).of(16.66306322)
      expect(an.present_value(rate: 0.05)).to be_within(eps).of(14.89812726)
      expect(an.present_value(rate: 0.06)).to be_within(eps).of(13.40616428)
    end
  end
end
