require 'spec_helper'


describe Puppet::Type.type(:xmlfile) do
  let(:testobject) {  Puppet::Type.type(:xmlfile) }
  
  # Test each of the inherited params and properties to ensure
  # validations are properly inherited.
  describe :path do
    it "should be fully-qualified" do
      expect {
        testobject.new(
          :name   => 'foo',
          :path   => 'my/path',
      )}.to raise_error(Puppet::Error, /paths must be fully qualified/)
    end
  end 
  
  describe :ctime do
    it "should be read-only" do
      expect {
        testobject.new(
          :name   => 'foo',
          :path   => '/my/path',
          :ctime  => 'somevalue',
      )}.to raise_error(Puppet::Error, /read-only/)
    end
  end 
  
  describe :mtime do
    it "should be read-only" do
      expect {
        testobject.new(
          :name   => 'foo',
          :path   => '/my/path',
          :mtime  => 'somevalue',
      )}.to raise_error(Puppet::Error, /read-only/)
    end
  end 
  
  describe :group do
    it "should not accept empty values" do
      expect {
        testobject.new(
         :name   => 'foo',
         :path   => '/my/path',
         :group  => '',
      )}.to raise_error(Puppet::Error, /Invalid group name/)  
    end
  end
  
  describe :mode do
    it "should perform validations" do
      expect {
        testobject.new(
         :name   => 'foo',
         :path   => '/my/path',
         :mode   => 'fghl',
      )}.to raise_error(Puppet::Error, /file mode specification is invalid/)  
    end
  end
  
  describe :source do
    it "should not accept a relative URL" do
      expect {
        testobject.new(
         :name   => 'foo',
         :path   => '/my/path',
         :source => 'modules/puppet/file',
      )}.to raise_error(Puppet::Error, /Cannot use relative URLs/)  
    end
  end
end