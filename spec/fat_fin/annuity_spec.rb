  #   def test_annuities
  #     an = Annuity.new(periods: 28, amount: 1.0)

  #     assert_in_delta(24.31644316, an.present_value(rate: 0.01), 0.01, 'Annuity[1]')
  #     assert_in_delta(21.28127236, an.present_value(rate: 0.02), 0.01, 'Annuity[1]')
  #     assert_in_delta(18.76410823, an.present_value(rate: 0.03), 0.01, 'Annuity[1]')
  #     assert_in_delta(16.66306322, an.present_value(rate: 0.04), 0.01, 'Annuity[1]')
  #     assert_in_delta(14.89812726, an.present_value(rate: 0.05), 0.01, 'Annuity[1]')
  #     assert_in_delta(13.40616428, an.present_value(rate: 0.06), 0.01, 'Annuity[1]')
  #   end
