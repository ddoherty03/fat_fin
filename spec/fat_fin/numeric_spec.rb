module FatFin
  RSpec.describe Numeric do
    using NumericExcelExtension

    it "A Numeric can be converted to an Excel date" do
      expect(0.excel_date).to eq(Date.parse('1899-12-31'))
      expect(59.excel_date).to eq(Date.parse('1900-02-28'))
      expect(60.excel_date).to eq(Date.parse('1900-03-01'))
      expect(61.excel_date).to eq(Date.parse('1900-03-01'))
      expect(21_085.excel_date).to eq(Date.parse('1957-09-22'))
    end
  end
end
