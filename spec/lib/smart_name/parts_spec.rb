# encoding: utf-8
require_relative "../../spec_helper"

RSpec.describe SmartName::Parts do
  describe 'parts and pieces' do
    it 'produces simple strings for parts' do
      'A+B+C+D'.to_name.parts.should == %w( A B C D )
    end

    it 'produces simple name objects for part_names' do
      'A+B+C+D'.to_name.part_names.should == %w( A B C D ).map(&:to_name)
    end

    it 'produces compound strings for pieces' do
      'A+B+C+D'.to_name.pieces.should == %w( A B C D A+B A+B+C A+B+C+D )
    end

    it 'produces compound name objects for piece_names' do
      'A+B+C+D'.to_name.piece_names.should ==
        %w( A B C D A+B A+B+C A+B+C+D ).map(&:to_name)
    end
  end

  describe '#left_name' do
    it 'returns nil for non junction' do
      'a'.to_name.left_name.should == nil
    end

    it 'returns parent for parent' do
      'a+b+c+d'.to_name.left_name.should == 'a+b+c'
    end
  end

  describe '#tag_name' do
    it 'returns last part of plus card' do
      'a+b+c'.to_name.tag.should == 'c'
    end

    it 'returns name of simple card' do
      'a'.to_name.tag.should == 'a'
    end
  end

  describe '#replace_part' do
    it 'replaces first name part' do
      'a+b'.to_name.replace_part('a', 'x').to_s.should == 'x+b'
    end
    it 'replaces second name part' do
      'a+b'.to_name.replace_part('b', 'x').to_s.should == 'a+x'
    end
    it 'replaces two name parts' do
      'a+b+c'  .to_name.replace_part('a+b', 'x').to_s.should == 'x+c'
      'a+b+c+d'.to_name.replace_part('a+b', 'e+f').to_s.should == 'e+f+c+d'
    end
    it "doesn't replace two part tag" do
      'a+b+c'.to_name.replace_part('b+c', 'x').to_s.should == 'a+b+c'
    end
  end
end
