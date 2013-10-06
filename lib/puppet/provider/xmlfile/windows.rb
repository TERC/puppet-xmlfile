# Not so sure about this one.
Puppet::Type.type(:xmlfile).provide(:xmlfile_windows, :parent => Puppet::Type.type(:file).provider(:windows)) do
  confine :operatingsystem => :windows
  
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