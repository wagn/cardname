# encoding: utf-8
require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe SmartName do
  describe '#key' do
    it 'should remove spaces' do
      'this    Name'.to_name.key.should == 'this_name'
    end

    it 'should have initial _ for initial cap' do
      'This Name'.to_name.key.should == 'this_name'
    end

    it 'should have initial _ for initial cap' do
      '_This Name'.to_name.key.should == 'this_name'
    end

    it 'should singularize' do
      'ethans'.to_name.key.should == 'ethan'
    end

    it 'should underscore' do
      'ThisThing'.to_name.key.should == 'this_thing'
    end

    it 'should handle plus cards' do
      'ThisThing+Ethans'.to_name.key.should == 'this_thing+ethan'
    end

    it 'should retain * for star cards' do
      '*right'.to_name.key.should == '*right'
    end

    it "should not singularize double s's" do
      'grass'.to_name.key.should == 'grass'
    end

    it "should not singularize letter 'S'" do
      'S'.to_name.key.should == 's'
    end

    it 'should handle unicode characters' do
      'Mañana'.to_name.key.should == 'mañana'
    end

    it 'should handle weird initial characters' do
      '__you motha @#$'.to_name.key.should == 'you_motha'
      '?!_you motha @#$'.to_name.key.should == 'you_motha'
    end

    it 'should allow numbers' do
      '3way'.to_name.key.should == '3way'
    end

    it 'internal plurals' do
      'cards hooks label foos'.to_name.key.should == 'card_hook_label_foo'
    end

    it 'should handle html entities' do
      # This no longer takes off the s, is singularize broken now?
      'Jean-fran&ccedil;ois Noubel'.to_name.key.should == 'jean_françoi_noubel'
    end
  end

  describe 'unstable keys' do
    context 'stabilize' do
      before do
        SmartName.stabilize = true
      end
      it 'should uninflect until key is stable' do
        "matthias".to_name.key.should == "matthium"
      end
    end

    context 'do not stabilize' do
      before do
        SmartName.stabilize = false
      end
      it 'should not uninflect unstable names' do
        "ilias".to_name.key.should == "ilias"
      end
    end
  end

  describe '#valid' do
    it 'accepts valid names' do
      'this+THAT'.to_name.should be_valid
      'THE*ONE*AND$!ONLY'.to_name.should be_valid
    end

    it 'rejects invalide names' do
      'Tes~sd'.to_name.should_not be_valid
      'TEST/DDER'.to_name.should_not be_valid
    end
  end

  describe '#include?' do
    context 'A+B+C' do
      let(:name) { "A+B+CD+EF".to_name }
      it '"includes "A"' do
        expect(name.include? ("A")).to be_truthy
      end
      it '"includes "a"' do
        expect(name.include? ("a")).to be_truthy
      end
      it '"includes "B"' do
        expect(name.include? ("B")).to be_truthy
      end
      it '"includes "A+B"' do
        expect(name.include? ("A+B")).to be_truthy
      end
      it '"includes "CD+EF"' do
        expect(name.include? ("CD+EF")).to be_truthy
      end
      it '"includes "A+B+CD+EF"' do
        expect(name.include? ("A+B+CD+EF")).to be_truthy
      end
      it '"does not include "A+B+C"' do
        expect(name.include? ("A+B+C")).to be_falsey
      end
      it '"does not include "F"' do
        expect(name.include? ("F")).to be_falsey
      end
      it '"does not include "D+EF"' do
        expect(name.include? ("AD+EF")).to be_falsey
      end
    end
  end
end
