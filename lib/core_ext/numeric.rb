# frozen_string_literal: true

module NumericExcelExtension
  refine Numeric do
    # Convert a number to an Excel date
    def excel_date
      k = to_i <= 60 ? 1 : 0
      Date.new(1899, 12, 30) + to_i + k
    end
  end
end
