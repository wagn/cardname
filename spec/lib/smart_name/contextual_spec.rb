# encoding: utf-8
require_relative "../../spec_helper"

RSpec.describe SmartName::Contextual do
  describe '#to_absolute' do
    it 'handles _self, _whole, _' do
      expect('_self'.to_name.to_absolute('foo')).to eq('foo')
      expect('_whole'.to_name.to_absolute('foo')).to eq('foo')
      expect('_'.to_name.to_absolute('foo')).to eq('foo')
    end

    it 'handles _left' do
      expect('_left+Z'.to_name.to_absolute('A+B+C')).to eq('A+B+Z')
    end

    it 'handles white space' do
      expect('_left + Z'.to_name.to_absolute('A+B+C')).to eq('A+B+Z')
    end

    it 'handles _right' do
      expect('_right+bang'.to_name.to_absolute('nutter+butter')).to eq('butter+bang')
      expect('C+_right'.to_name.to_absolute('B+A')).to eq('C+A')
    end

    it 'handles leading +' do
      expect('+bug'.to_name.to_absolute('hum')).to eq('hum+bug')
    end

    it 'handles trailing +' do
      expect('bug+'.to_name.to_absolute('tracks')).to eq('bug+tracks')
    end

    it 'handles _(numbers)' do
      expect('_1'.to_name.to_absolute('A+B+C')).to eq('A')
      expect('_1+_2'.to_name.to_absolute('A+B+C')).to eq('A+B')
      expect('_2+_3'.to_name.to_absolute('A+B+C')).to eq('B+C')
    end

    it 'handles _LLR etc' do
      expect('_R'.to_name.to_absolute('A+B+C+D+E')).to    eq('E')
      expect('_L'.to_name.to_absolute('A+B+C+D+E')).to    eq('A+B+C+D')
      expect('_LR'.to_name.to_absolute('A+B+C+D+E')).to   eq('D')
      expect('_LL'.to_name.to_absolute('A+B+C+D+E')).to   eq('A+B+C')
      expect('_LLR'.to_name.to_absolute('A+B+C+D+E')).to  eq('C')
      expect('_LLL'.to_name.to_absolute('A+B+C+D+E')).to  eq('A+B')
      expect('_LLLR'.to_name.to_absolute('A+B+C+D+E')).to eq('B')
      expect('_LLLL'.to_name.to_absolute('A+B+C+D+E')).to eq('A')
    end

    context 'mismatched requests' do
      it 'returns _self for _left or _right on simple cards' do
        expect('_left+Z'.to_name.to_absolute('A')).to eq('A+Z')
        expect('_right+Z'.to_name.to_absolute('A')).to eq('A+Z')
      end

      it 'handles bogus numbers' do
        expect('_1'.to_name.to_absolute('A')).to eq('A')
        expect('_1+_2'.to_name.to_absolute('A')).to eq('A+A')
        expect('_2+_3'.to_name.to_absolute('A')).to eq('A+A')
      end

      it 'handles bogus _llr requests' do
        expect('_R'.to_name.to_absolute('A')).to eq('A')
        expect('_L'.to_name.to_absolute('A')).to eq('A')
        expect('_LR'.to_name.to_absolute('A')).to eq('A')
        expect('_LL'.to_name.to_absolute('A')).to eq('A')
        expect('_LLR'.to_name.to_absolute('A')).to eq('A')
        expect('_LLL'.to_name.to_absolute('A')).to eq('A')
        expect('_LLLR'.to_name.to_absolute('A')).to eq('A')
        expect('_LLLL'.to_name.to_absolute('A')).to eq('A')
      end
    end
  end

  describe '#to_show' do
    it 'ignores ignorables' do
      expect('you+awe'.to_name.to_show('you')).to eq('+awe')
      expect('me+you+awe'.to_name.to_show('you')).to eq('me+awe') #HMMM..... what should this do?
      expect('me+you+awe'.to_name.to_show('me' )).to eq('+you+awe')
      expect('me+you+awe'.to_name.to_show('me','you')).to eq('+awe')
      expect('me+you'.to_name.to_show('me','you')).to eq('me+you')
      expect('?a?+awe'.to_name.to_show('A')).to eq('+awe')
      expect('+awe'.to_name.to_show()).to eq('+awe')
      expect('+awe'.to_name.to_show(nil)).to eq('+awe')
    end
  end

end
