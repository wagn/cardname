# encoding: utf-8
require File.expand_path('../spec_helper', File.dirname(__FILE__))
require 'core_ext'


describe SmartName do

  describe "#key" do
    it "should remove spaces" do
      "January 1, 1999".to_name.key.should == "JD2451180"
    end

    it "should do Y M D" do
      "1999-1-31".to_name.key.should == "JD2451210"
    end

    it "should do M D Y based on range" do
      "1 31 1999".to_name.key.should == "JD2451210"
    end

    it "should default to D M Y" do
      "1 10 1999".to_name.key.should == "JD2451453"
    end

    it "should ignore week day" do
      "Friday, Jan 10, 1999".to_name.key.should == "JD2451189"
    end

    it "should not do year in the middle" do
      "Jan 1999 10".to_name.key.should == "jan_1999_10"
    end
  end
end
