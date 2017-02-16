# encoding: utf-8
require_relative "../../spec_helper"

RSpec.describe SmartName::Contextual do
  describe '#to_absolute' do
    it 'handles _self, _whole, _' do
      '_self'.to_name.to_absolute('foo').should == 'foo'
      '_whole'.to_name.to_absolute('foo').should == 'foo'
      '_'.to_name.to_absolute('foo').should == 'foo'
    end

    it 'handles _left' do
      '_left+Z'.to_name.to_absolute('A+B+C').should == 'A+B+Z'
    end

    it 'handles white space' do
      '_left + Z'.to_name.to_absolute('A+B+C').should == 'A+B+Z'
    end

    it 'handles _right' do
      '_right+bang'.to_name.to_absolute('nutter+butter').should == 'butter+bang'
      'C+_right'.to_name.to_absolute('B+A').should == 'C+A'
    end

    it 'handles leading +' do
      '+bug'.to_name.to_absolute('hum').should == 'hum+bug'
    end

    it 'handles trailing +' do
      'bug+'.to_name.to_absolute('tracks').should == 'bug+tracks'
    end

    it 'handles _(numbers)' do
      '_1'.to_name.to_absolute('A+B+C').should == 'A'
      '_1+_2'.to_name.to_absolute('A+B+C').should == 'A+B'
      '_2+_3'.to_name.to_absolute('A+B+C').should == 'B+C'
    end

    it 'handles _LLR etc' do
      '_R'.to_name.to_absolute('A+B+C+D+E').should    == 'E'
      '_L'.to_name.to_absolute('A+B+C+D+E').should    == 'A+B+C+D'
      '_LR'.to_name.to_absolute('A+B+C+D+E').should   == 'D'
      '_LL'.to_name.to_absolute('A+B+C+D+E').should   == 'A+B+C'
      '_LLR'.to_name.to_absolute('A+B+C+D+E').should  == 'C'
      '_LLL'.to_name.to_absolute('A+B+C+D+E').should  == 'A+B'
      '_LLLR'.to_name.to_absolute('A+B+C+D+E').should == 'B'
      '_LLLL'.to_name.to_absolute('A+B+C+D+E').should == 'A'
    end

    context 'mismatched requests' do
      it 'returns _self for _left or _right on simple cards' do
        '_left+Z'.to_name.to_absolute('A').should == 'A+Z'
        '_right+Z'.to_name.to_absolute('A').should == 'A+Z'
      end

      it 'handles bogus numbers' do
        '_1'.to_name.to_absolute('A').should == 'A'
        '_1+_2'.to_name.to_absolute('A').should == 'A+A'
        '_2+_3'.to_name.to_absolute('A').should == 'A+A'
      end

      it 'handles bogus _llr requests' do
        '_R'.to_name.to_absolute('A').should == 'A'
        '_L'.to_name.to_absolute('A').should == 'A'
        '_LR'.to_name.to_absolute('A').should == 'A'
        '_LL'.to_name.to_absolute('A').should == 'A'
        '_LLR'.to_name.to_absolute('A').should == 'A'
        '_LLL'.to_name.to_absolute('A').should == 'A'
        '_LLLR'.to_name.to_absolute('A').should == 'A'
        '_LLLL'.to_name.to_absolute('A').should == 'A'
      end
    end
  end

  describe '#to_show' do
    it 'ignores ignorables' do
      'you+awe'.to_name.to_show('you').should == '+awe'
      'me+you+awe'.to_name.to_show('you').should == 'me+awe' #HMMM..... what should this do?
      'me+you+awe'.to_name.to_show('me' ).should == '+you+awe'
      'me+you+awe'.to_name.to_show('me','you').should == '+awe'
      'me+you'.to_name.to_show('me','you').should == 'me+you'
      '?a?+awe'.to_name.to_show('A').should == '+awe'
      '+awe'.to_name.to_show().should == '+awe'
      '+awe'.to_name.to_show(nil).should == '+awe'
    end
  end

end
