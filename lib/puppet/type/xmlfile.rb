require 'puppet/type/file'
require 'puppet/util/checksums'
# It's not really a provider but there just isn't a great place to put this kind of thing
# ok?
require 'puppet/provider/xmlfile/lens'

# Equivalent to the file resource in every way but how it handles content.
Puppet::Type.newtype(:xmlfile, :parent => Puppet::Type::File) do
  @doc = <<-'EOT'
    An extension of the base file resource type.  An xmlfile behaves like a file in all ways
    except that its content can be modified via xmlfile_modification resources.
    
    This enables the mixing of exported or virtual content and
    templated or static content, while managing the end-result as a single resource.
  EOT
  
  # Ignore rather than include in case the base class is messed with.  
  # Note that the parameters defined locally don't actually exist yet until this block is evaluated so to
  # act based on that kind of introspection you would need to move all of this into another file
  # that gets required after this block.
  IGNORED_PARAMETERS = [ :backup, :recurse, :recurselimit, :force, 
                         :ignore, :links, :purge, :sourceselect, :show_diff,
                         :provider, :checksum, :type, :replace ]
  IGNORED_PROPERTIES = [ :ensure, :target, :content ]
  
  # Finish up extending the File type - define parameters and properties
  # that aren't ignored and aren't otherwise defined.
  
  # Parameters - appear to require a lookup
  Puppet::Type::File.parameters.each do |inherit|
    unless IGNORED_PARAMETERS.include?(inherit)
      klass = "Puppet::Type::File::Parameter#{inherit.to_s.capitalize}"
      begin
        newparam(inherit, :parent => self.const_get(klass))
      rescue 
        warning "Inheritance assumption case problem: #{klass} undefined but not ignored."
      end
    end
  end
  
  # Properties are easier as the class is in the instance variable
  Puppet::Type::File.properties.each do |inherit|
    unless IGNORED_PROPERTIES.include?(inherit.name)
      newproperty(inherit.name.to_sym, :parent => inherit)
    end
  end
  
  # Need to override the following two functions in order to
  # ignore recurse and backup parameters
  def bucket        # to ignore :backup
    nil
  end

  def eval_generate # to ignore :recurse
    return []
  end
  
  # Now our code starts
  ensurable
  
  # Actual file content
  newproperty(:content) do
    desc <<-'EOT'
      The desired contents of a file, as a string. This attribute is mutually
      exclusive with `source`.
    EOT
    include Puppet::Util::Checksums
    
    # Convert the current value into a checksum so we don't pollute the logs
    def is_to_s(value)
      md5(value)
    end

    # Convert what the value should be into a checksum so we don't pollute the logs
    def should_to_s(value)
      md5(value)
    end
  end

  # Generates content
  def should_content # Ape the name from property::should
    return @should_content if @should_content # Only do this ONCE
    @should_content = ""
    
    # Get our base content
    # Need to retrieve and render our current content
    if ! self[:content].nil?
      content = self[:content]
    elsif ! self[:source].nil?
      content = Puppet::FileServing::Content.indirection.find(self[:source], :environment => catalog.environment).content
    else
      content = String.new # No content so we start with a base string.
    end
    # Wrap it in a REXML::Document
    xml_content = REXML::Document.new(content)
    
    # Need to order this by requirements.  I *think* puppet does this in the catalog, but I'm not positive.
    catalog.resources.select{ |resource| resource if resource.is_a?(Puppet::Type.type(:xmlfile_modification)) and 
                                                     resource[:file] == self[:path] }.each do |resource|
      process = XmlLens.new(xml_content, resource[:changes], resource[:onlyif])
      xml_content = process.evaluate
    end
    
    # Write the final xml into the instance var.
    xml_content.write(@should_content)
    return @should_content
  end
  
  # Make sure we only set source or content, but not both.
  validate do
    if self[:source] and self[:content]
      raise(Puppet::Error, "Can specify either source or content but not both.")
    end
  end
end
