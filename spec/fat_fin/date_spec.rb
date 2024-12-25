module FatFin
  RSpec.describe Date do
    describe "date arithmetic" do
      it "subtracts dates" do
        expect(Date.new(1957, 9, 22)).to eq(Date.parse('1957-09-22'))
        expect(Date.parse('2005-05-14') - Date.parse('2005-03-14')).to eq(61)
      end

      it "Date performs Excel date arithmetic" do
        expect(Date.excel(0)).to eq(Date.parse('1899-12-31'))
        expect(Date.excel(59)).to eq(Date.parse('1900-02-28'))
        expect(Date.excel(60)).to eq(Date.parse('1900-03-01'))
        expect(Date.excel(61)).to eq(Date.parse('1900-03-01'))
        expect(Date.excel(21_085)).to eq(Date.parse('1957-09-22'))
      end
    end
  end
end
#   def test_month_diff
#     # Integral months
#     assert_equal(14, Date.parse('2017-11-15')
#                      .whole_month_diff(Date.parse('2016-09-15')),
#                  'month_diff_1')
#     assert_equal(117, Date.parse('2017-11-15')
#                       .whole_month_diff(Date.parse('2008-02-15')),
#                  'month_diff_2')
#     assert_equal(0, Date.parse('2007-04-30')
#                     .whole_month_diff(Date.parse('2007-04-01')),
#                  'month_diff_3')
#     assert_equal(1, Date.parse('2007-04-30')
#                     .whole_month_diff(Date.parse('2007-03-31')),
#                  'month_diff_4')
#     assert_equal(1, Date.parse('2007-04-30')
#                     .whole_month_diff(Date.parse('2007-03-30')),
#                  'month_diff_5')
#     # Fractional months
#     assert_equal(14, Date.parse('2017-11-15')
#                      .month_diff(Date.parse('2016-09-15')),
#                  'month_diff_6')
#     assert_equal(117, Date.parse('2017-11-15')
#                       .month_diff(Date.parse('2008-02-15')),
#                  'month_diff_7')
#     assert_equal(29.0 / 30.0, Date.parse('2007-04-30')
#                               .month_diff(Date.parse('2007-04-01')),
#                  'month_diff_8')
#     assert_equal(1, Date.parse('2007-04-30')
#                     .month_diff(Date.parse('2007-03-31')),
#                  'month_diff_9')
#     assert_equal(1, Date.parse('2007-04-30')
#                     .month_diff(Date.parse('2007-03-30')),
#                  'month_diff_10')
#   end
