Puppet::Type.type(:xmlfile).provide(:xmlfile_posix, :parent => Puppet::Type.type(:file).provider(:posix)) do
  confine :feature => :posix

  def exists?
    resource.exist?
  end

  def create
    send("content=", resource.should_content)
    resource.send(:property_fix)
  end

  def destroy
    File.unlink(resource[:path]) if exists?
  end

  def content
    actual = File.read(resource[:path]) rescue nil
    (actual == resource.should_content) ? resource[:content] : actual
  end
  
  def content=(value)
    File.open(resource[:path], 'w') do |handle|
      handle.print resource.should_content
    end
  end
end