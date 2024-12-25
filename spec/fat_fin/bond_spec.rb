# frozen_string_literal: true

module FatFin
  RSpec.describe Bond do

    describe '#price' do
      it 'Example 1' do
        b1 = Bond.new(maturity: '2017-11-15',
                      coupon: 0.0575,
                      face: 100.0,
                      frequency: 2)
        expect(b1.price(yld: 0.065, settle_date: '2008-02-15')).to be_within(0.01).of(94.6221)
      end

      it 'Example 2' do
        b2 = Bond.new(maturity: '2007-01-02',
                      coupon: 0.055,
                      face: 100.0,
                      frequency: 2)
        expect(b2.price(yld: 0.06876, settle_date: '2005-06-30')).to be_within(0.01).of(98.0629)
      end

      it 'Example 3' do
        b3 = Bond.new(maturity: '2015-07-01',
                      coupon: 0.1,
                      face: 1000.0,
                      frequency: 2)
        expect(b3.price(yld: 0.12, settle_date: '2005-07-01')).to be_within(0.01).of(885.307)
      end

      it 'Example 4' do
        b4 = Bond.new(maturity: '2010-07-01',
                      coupon: 0,
                      face: 1000.0,
                      frequency: 2)
        expect(b4.price(yld: 0.06, settle_date: '2005-07-01')).to be_within(0.01).of(744.09)
      end

      it 'Example 5' do
        b5 = Bond.new(maturity: '2011-06-17',
                      coupon: 0.0422,
                      face: 100.0,
                      frequency: 2)
        expect(b5.price(yld: 0.005, settle_date: '2010-06-30')).to be_within(0.01).of(103.57)
      end
    end

    describe '#yield' do
      it 'Excel example 1' do
        b1 = Bond.new(maturity: '2007-11-15',
                      coupon: 0.0575,
                      face: 100.0,
                      frequency: 2)
        expect(b1.yld(price: 95.04287, settle_date: '1999-02-15')).to be_within(0.0001).of(0.065)
      end

      it 'Excel example 2' do
        b2 = Bond.new(maturity: '2010-03-22',
                      coupon: 0.05,
                      face: 100.0,
                      frequency: 2)
        expect(b2.yld(price: 95.92, settle_date: '2007-09-22')).to be_within(0.0001).of(0.068)
      end

      it 'Excel example 3' do
        b3 = Bond.new(maturity: '2016-11-15',
                      coupon: 0.0575,
                      face: 100.0,
                      frequency: 2)
        expect(b3.yld(price: 95.92, settle_date: '2008-02-15')).to be_within(0.0001).of(0.0636)
      end

      it 'Excel example 4' do
        b4 = Bond.new(maturity: '2007-11-30',
                      coupon: 0.044,
                      face: 100.0,
                      frequency: 2)
        expect(b4.yld(price: 100.0, settle_date: '2007-10-31')).to be_within(0.0001).of(0.0432)
      end
    end

    describe '#macaulay_duration' do
      it 'Investopedia example' do
        # Examples from Investopedia
        # http://www.investopedia.com/university/advancedbond/advancedbond5.asp
        b = Bond.new(maturity: '2010-07-01',
                     coupon: 0.05,
                     face: 1000.0,
                     frequency: 1)
        expect(b.macaulay_duration(yld: 0.05, settle_date: '2005-07-01')).to be_within(0.01).of(4.55)
      end

      it 'Excel example' do
        # Excel example
        b = Bond.new(maturity: '2016-01-01',
                     coupon: 0.08,
                     face: 100.0,
                     frequency: 2)
        expect(b.macaulay_duration(yld: 0.09, settle_date: '2008-01-01')).to be_within(0.00001).of(5.993775)
      end

      it 'LibreOffice Calc example' do
        # OpenOffice Calc example
        b = Bond.new(maturity: '2006-01-01',
                     coupon: 0.08,
                     face: 100.0,
                     frequency: 2)
        expect(b.macaulay_duration(yld: 0.09, settle_date: '2001-01-01')).to be_within(0.1).of(4.2)
      end
    end

    describe '#modified_duration' do
      it 'Investopedia example' do
        b = Bond.new(maturity: '2010-07-01',
                     coupon: 0.05,
                     face: 1000.0,
                     frequency: 1)
        expect(b.modified_duration(yld: 0.05, settle_date: '2005-07-01')).to be_within(0.01).of(4.33)
      end

      it 'Excel example' do
        b = Bond.new(maturity: '2016-01-01',
                     coupon: 0.08,
                     face: 100.0,
                     frequency: 2)
        expect(b.modified_duration(yld: 0.09, settle_date: '2008-01-01')).to be_within(0.01).of(5.73567)
      end

      it 'Libreoffice example' do
        b = Bond.new(maturity: '2006-01-01',
                     coupon: 0.08,
                     face: 100.0,
                     frequency: 2)
        expect(b.modified_duration(yld: 0.09, settle_date: '2001-01-01', convention: 1)).to be_within(0.01).of(4.02)
      end
    end
  end
end
