# encoding: utf-8
require File.expand_path('../spec_helper', File.dirname(__FILE__))
require 'core_ext'


describe SmartName do

  describe '#key' do
    it 'should remove spaces and non-key chars' do
      n=' January -_& 1, 1999'.to_name
      n.pretty_key.should == 'Date: 01/01/99'
      n.key.should == 'DACVm7A'
    end

    it 'should do Y M D' do
      n='1999-1-31'.to_name
      n.pretty_key.should == 'Date: 01/31/99'
      n.key.should == 'DACVnCg'
    end

    it 'should not do Y D M' do
      n='1999-31-1'.to_name
      n.pretty_key.should == 'Long: 1999::Long: 31::Long: 1'
      n.key.should == 'LAAAHzw_LAAAAHw_LAAAAAQ'
    end

    it 'should do M D Y based on range' do
      n='1 31 1999'.to_name
      n.pretty_key.should == 'Date: 01/31/99'
      n.key.should == 'DACVnCg'
    end

    it 'should default to D M Y' do
      n='1 10 1999'.to_name
      n.pretty_key.should == 'Date: 10/01/99'
      n.key.should == 'DACVn/Q'
    end

    it 'should ignore week day' do
      n='Friday, Jan 10, 1999'.to_name
      n.pretty_key.should == 'Date: 10/01/99'
      n.key.should == 'DACVn/Q'
    end

    it 'should not do year in the middle' do
      n='Jan 1999 10'.to_name
      n.pretty_key.should == 'jan::Long: 1999::Long: 10'
      n.key.should == 'jan_LAAAHzw_LAAAACg'
    end

    it 'should not match unless right after ignored week day' do
      n='Friday, on Jan 10, 1999'.to_name
      n.pretty_key.should == 'friday::on::jan::Long: 10::Long: 1999'
      n.key.should == 'friday_on_jan_LAAAACg_LAAAHzw'
    end

    it 'matches after other keys' do
      n='some, key Jan 10, 1999'.to_name
      n.pretty_key.should == 'some::key::Date: 10/01/99'
      n.key.should == 'some_key_DACVn/Q'
    end

    it 'matches after number keys' do
      n='10 20 30, Jan 10, 1999'.to_name
      n.pretty_key.should == 'Long: 10::Long: 20::Long: 30::Date: 10/01/99'
      n.key.should == 'LAAAACg_LAAAAFA_LAAAAHg_DACVn/Q'
    end

    it 'matches after number keys, including time' do
      n='10 20 30, Jan 10, 1999 10am'.to_name
      n.pretty_key.should == 'Long: 10::Long: 20::Long: 30::Datetime: Fri Oct  1 10:00:00 1999'
      #n.key.should == 'LAAAACg_LAAAAFA_LAAAAHg_TAAAAADf0zHA' # Base64 encoding is different only in point version at semaphore
    end

    it 'matches after number keys, including time' do
      n='10 20 30, Jan 10, 1999 10AM'.to_name
      n.pretty_key.should == 'Long: 10::Long: 20::Long: 30::Datetime: Fri Oct  1 10:00:00 1999'
      #n.key.should == 'LAAAACg_LAAAAFA_LAAAAHg_TAAAAADf0zHA' # Base64 encoding is different only in point version at semaphore
    end

    it 'matches include 24 hour time' do
      n='Jan 10, 1999 22:00:00'.to_name
      n.pretty_key.should == 'Datetime: Fri Oct  1 22:00:00 1999'
      #n.key.should == 'TAAAAADf1dTA' # Base64 encoding is different only in point version at semaphore
    end

    it 'matches after number keys' do
      n='10 20 30, Jan 10, 1999'.to_name
      n.pretty_key.should == 'Long: 10::Long: 20::Long: 30::Date: 10/01/99'
      n.key.should == 'LAAAACg_LAAAAFA_LAAAAHg_DACVn/Q'
    end

    it 'matches number' do
      n= '0000012345678901234'.to_name
      n1= '   12345678901234'.to_name
      n2= '12345678901234'.to_name
      n.key.should == n1.key
      n.key.should == n2.key
      n.pretty_key.should == 'Long Long: 12345678901234'
      n.key.should == 'QAAALOnPOL/I'
    end
  end
end
