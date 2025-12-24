# frozen_string_literal: true

module FatFin
  # rubocop:disable RSpec/PredicateMatcher
  RSpec.describe Float do
    using FloatExtension

    describe '#close_to?' do
      context 'with magnitude between 0 and 1' do
        let(:abs_tol) { 1.0E-14 }

        it 'returns true for same positive numbers' do
          expect(1000001.0E-15.close_to?(1000002.0E-15, abs_tol:)).to be_truthy
          expect(1000001.0E-15.close_to?(1000001.0E-15, abs_tol:)).to be_truthy
        end

        it 'returns true for same negative numbers' do
          expect(-1000001.0E-15.close_to?(-1000002.0E-15, abs_tol:)).to be_truthy
          expect(-1000001.0E-15.close_to?(-1000001.0E-15, abs_tol:)).to be_truthy
        end

        it 'returns false for different positive numbers' do
          expect(1000010.0E-15.close_to?(1000020.0E-15, abs_tol:)).to be_truthy
          expect(1000020.0E-15.close_to?(1000010.0E-15, abs_tol:)).to be_truthy
        end

        it 'returns false for different negative numbers' do
          expect(-1000010.0E-15.close_to?(-1000020.0E-15, abs_tol:)).to be_truthy
          expect(-1000020.0E-15.close_to?(-1000010.0E-15, abs_tol:)).to be_truthy
        end
      end

      context 'with non-floats' do
        it 'converts other non-float to float' do
          expect(3.0001.close_to?(3, abs_tol: 0.001)).to be_truthy
          expect(3.0001.close_to?(Rational(3, 1), abs_tol: 0.001)).to be_truthy
          expect(3.0001.close_to?(Complex(3, 0), abs_tol: 0.001)).to be_truthy
        end
      end
    end

    describe '#precision' do
      it "knows the precision of a small posititve" do
        expect(0.0000000001.precision).to eq(10)
      end

      it "knows the precision of a small negative" do
        expect(-0.0000000001.precision).to eq(10)
      end

      it "knows the precision of a large posititve" do
        expect(123456789.1234.precision).to eq(0)
      end

      it "knows the precision of a large negative" do
        expect(-123456789.1234.precision).to eq(0)
      end
    end
  end
  # rubocop:enable RSpec/PredicateMatcher
end
