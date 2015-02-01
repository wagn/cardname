# encoding: utf-8
require File.expand_path('../spec_helper', File.dirname(__FILE__))
require 'core_ext'


describe SmartName do

  describe '#key' do
    it 'should remove spaces and non-key chars' do
      n=' January -_& 1, 1999'.to_name
      n.pretty_key.should == 'Date: 1999-01-01'
      n.key.should == 'D%%7KPg'
    end

    it 'should do Y M D' do
      n='1999-1-31'.to_name
      n.pretty_key.should == 'Date: 1999-01-31'
      n.key.should == 'D%%7KQ8'
    end

    it 'should not do Y D M' do
      n='1999-31-1'.to_name
      n.pretty_key.should == 'Long: 1999::Long: 31::Long: 1'
      n.key.should == 'L%%%%TD_L%%%%%T_L%%%%%-'
    end

    it 'should do M D Y based on range' do
      n='1 31 1999'.to_name
      n.pretty_key.should == 'Date: 1999-01-31'
      n.key.should == 'D%%7KQ8'
    end

    it 'should default to D M Y' do
      n='1 10 1999'.to_name
      n.pretty_key.should == 'Date: 1999-01-10'
      n.key.should == 'D%%7KPp'
    end

    it 'should ignore week day' do
      n='Friday, Jan 10, 1999'.to_name
      n.pretty_key.should == 'Date: 1999-01-10'
      n.key.should == 'D%%7KPp'
    end

    it 'should not do year in the middle' do
      n='Jan 1999 10'.to_name
      n.pretty_key.should == 'jan::Long: 1999::Long: 10'
      n.key.should == 'jan_L%%%%TD_L%%%%%8'
    end

    it 'should not match unless right after ignored week day' do
      n='Friday, on Jan 10, 1999'.to_name
      n.pretty_key.should == 'friday::on::jan::Long: 10::Long: 1999'
      n.key.should == 'friday_on_jan_L%%%%%8_L%%%%TD'
    end

    it 'matches after other keys' do
      n='some, key Jan 10, 1999'.to_name
      n.pretty_key.should == 'some::key::Date: 1999-01-10'
      n.key.should == 'some_key_D%%7KPp'
    end

    it 'matches after number keys' do
      n='15 20 30 aaa, Jan 10, 1999'.to_name
      n.pretty_key.should == 'Long: 15::Long: 20::Long: 30::aaa::Date: 1999-01-10'
      n.key.should == 'L%%%%%D_L%%%%%I_L%%%%%S_aaa_D%%7KPp'
    end

    it 'matches after number keys, including time' do
      n='15 20 30 bbb, Jan 10, 1999 10am'.to_name
      n.pretty_key.should == 'Long: 15::Long: 20::Long: 30::bbb::Datetime: Sun Jan 10 10:00:00 1999'
      n.key.should == 'L%%%%%D_L%%%%%I_L%%%%%S_bbb_T%%%%%%qa5cU'
    end

    it 'matches after number keys, including time' do
      n='15 20 30 b, Jan 10, 1999 10AM'.to_name
      n.pretty_key.should == 'Long: 15::Long: 20::Long: 30::b::Datetime: Sun Jan 10 10:00:00 1999'
      n.key.should == 'L%%%%%D_L%%%%%I_L%%%%%S_b_T%%%%%%qa5cU'
    end

    it 'matches include 24 hour time' do
      n='Jan 10, 1999 22:00:00'.to_name
      n.pretty_key.should == 'Datetime: Sun Jan 10 22:00:00 1999'
      n.key.should == 'T%%%%%%qaG9U'
    end

    it 'handles standard (%c) format including 24 hour time' do
      n='Fri Oct  1 22:00:00 1999'.to_name
      n.pretty_key.should == 'Datetime: Fri Oct  1 22:00:00 1999'
      n.key.should == 'T%%%%%%rxGvU'
    end

    it 'matches after number keys' do
      n='AA 20 39, Jan 10, 1999'.to_name
      n.pretty_key.should == 'aa::Long: 20::Long: 39::Date: 1999-01-10'
      n.key.should == 'aa_L%%%%%I_L%%%%%b_D%%7KPp'
    end

    it 'matches number' do
      n= '0000012345678901234'.to_name
      n1= '   12345678901234'.to_name
      n2= '12345678901234'.to_name
      n.key.should == n1.key
      n.key.should == n2.key
      n.pretty_key.should == 'Long Long: 12345678901234'
      n.key.should == 'Q%%%0ndnnWzm'
    end

    it 'handles number bigger that long long' do
      n= '00000123456789012345678901111'.to_name
      n1= '   123456789012345678901111'.to_name
      n2= '123456789012345678901111'.to_name
      n.key.should == n1.key
      n.key.should == n2.key
      n.pretty_key.should == 'Long Long: 123456789012345678901111'
      n.key.should == 'QO77gT28-gZexr'
    end

    it 'matches number bigger than long in parts' do
      n= '00000123456789011111_2345678901111'.to_name
      n1= '   123456789011111_2345678901111'.to_name
      n2= '123456789011111_0000002345678901111'.to_name
      n.key.should == n1.key
      n.key.should == n2.key
      n.pretty_key.should == 'Long: 123456789011111::Long: 2345678901111'
      n.key.should == 'LQ2W41Reb_LW6ZKsxr'
    end
  end
end
