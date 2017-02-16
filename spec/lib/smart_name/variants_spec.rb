# encoding: utf-8
require_relative "../../spec_helper"

RSpec.describe SmartName::Variants do
  describe '#url_key' do
    cardnames = [
      'GrassCommons.org',
      'Oh you @##',
      "Alice's Restaurant!",
      'PB &amp; J',
      'Mañana'
    ].map(&:to_name)

    cardnames.each do |cardname|
      it 'should have the same key as the name' do
        cardname.key.should == cardname.url_key.to_name.key
      end
    end

    it 'should handle compound names cleanly' do
      'What?+the!+heck$'.to_name.url_key.should == 'What+the+heck'
    end
  end


  describe '#safe_key' do
    it 'subs pluses & stars' do
      'Alpha?+*be-ta'.to_name.safe_key.should == 'alpha-Xbe_tum'
    end
  end
end
