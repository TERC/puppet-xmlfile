require 'spec_helper'

describe Puppet::Type.type(:xmlfile_modification) do
  let(:testobject) {  Puppet::Type.type(:xmlfile_modification) }
  
  describe :file do
    it "should be a fully-qualified path" do
      expect {
        testobject.new(
          :name   => 'foo',
          :file   => 'my/path',
      )}.to raise_error(Puppet::Error, /paths must be fully qualified/)
    end
    it "should be required"
  end
  
  describe :changes do
    it "should require a fully-qualified xpath" do
      expect {
        testobject.new(
          :name   => "test",
          :file   => "/my/path",
          :changes => [ "set blah/bloo/hah \"test\""],
      )}.to raise_error(Puppet::Error, /invalid xpath/)
    end
    it "should not accept invalid commands" do
      expect {
        testobject.new(
          :name   => "test",
          :file   => "/my/path",
          :changes => [ "sets /blah/bloo/hah \"test\""],
      )}.to raise_error(Puppet::Error, /Unrecognized command/)
    end
    describe "ins" do
      it "should validate syntax" do
        expect {
          testobject.new(
            :name   => "test",
            :file   => "/my/path",
            :changes => [ "ins blue befores red"],
        )}.to raise_error(Puppet::Error, /Invalid syntax/)
      end
    end
    describe "set" do
      it "should validate syntax" do
        expect {
          testobject.new(
            :name   => "test",
            :file   => "/my/path",
            :changes => [ "set /blah/bloo/hah test"],
        )}.to raise_error(Puppet::Error, /Invalid syntax/)
      end
    end
  end
  
  describe :onlyif do
    it "should require a fully-qualified xpath" do
      expect {
        testobject.new(
          :name   => "test",
          :file   => "/my/path",
          :onlyif => [ "get blah/bloo/hah == \"test\""],
      )}.to raise_error(Puppet::Error, /invalid xpath/)
    end
    it "should not accept invalid commands" do
      expect {
        testobject.new(
          :name   => "test",
          :file   => "/my/path",
          :onlyif => [ "gets /blah/bloo/hah \"test\""],
      )}.to raise_error(Puppet::Error, /Unrecognized command/)
    end
    describe "get" do
      it "should validate syntax" do
        expect {
          testobject.new(
            :name   => "test",
            :file   => "/my/path",
            :onlyif => [ "get /blah/bloo/hah test"],
        )}.to raise_error(Puppet::Error, /Invalid syntax/)
      end
    end
    
    describe "match" do
      it "should validate syntax" do
        expect {
          testobject.new(
            :name   => "test",
            :file   => "/my/path",
            :onlyif => [ "match /blah/bloo/hah test"],
        )}.to raise_error(Puppet::Error, /Invalid syntax/)
      end
    end
  end
end