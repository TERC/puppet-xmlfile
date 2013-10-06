# TERC Puppet XMLFile Library #

Provides the xmlfile and xmlfile_modification types and associated providers.

### What? ###
See the type reference.

### Why? ###
I kept running into cases where what I really, really wanted to do was apply augeas lenses to a template, but 
this was problematic.  My first thought was "my kingdom for an array!" and the led to the databucket library, which is,
unfortunately, probably not reliable enough for production or capable of being made reliable enough for production.  It 
was a fun intellectual exercise though!

### How? ###
By extending the Puppet file and using some providers to realize the modifications that exist in the catalog at the time 
of application.

The changes are applied via the XMLLens class, which sort of fakes being augeas.

### License? ###
See the LICENSE file.

## Type Reference ##

### xmlfile ###

An extension of the base file resource type.  An xmlfile behaves like a file in all ways
except that its content can be modified via xmlfile_modification resources.

This enables the mixing of exported or virtual content and templated or static content, while managing the 
end-result as a single resource.

The following attributes are inherited from the file(see: http://docs.puppetlabs.com/references/latest/type.html#file) type:
- ctime (read-only)
- group
- mode
- mtime (read-only)
- owner
- selinux_ignore_defaults
- selrange
- selrole
- seltype
- seluser
- source

#### Attributes ####

path
: (**Namevar:** If omitted, this parameter's value defaults to the resource's title.)

  The path to the file to manage.  Must be fully qualified.

  On Windows, the path should include the drive letter and should use `/` as
  the separator character (rather than `\\`).
  
content
: (**Property:** This attribute represents the starting state on the target system.)
  The desired base contents of a file, as a string. This attribute is mutually
  exclusive with `source`.
  
  Modifications are applied to this value.

ensure
: The basic property that the resource should be in.  Valid values are `present`, `absent`.

provider
: The specific backend to use for this `xmlfile`
  resource. You will seldom need to specify this --- Puppet will usually
  discover the appropriate provider for your platform.
  Available providers are:

  xmlfile_posix
  : 

  xmlfile_windows
  : NOTE: Untested

----------------

### xmlfile_modification ###

Apply a change or an array of changes constrained by conditionals, to a specified xml file
using syntax similar to the augeas XML lens.  Changes are applied in memory
during content generation when the catalog is applied.

Requires:

- REXML

Sample usage with strings:

    xmlfile_modification{"test" :
      file    => "/etc/activemq/activemq.conf.xml",
      changes => "set /beans/broker/transportConnectors/transportConnector[last()+1]/#attribute/name \"test\"",
      onlyif  => "match /beans/broker/transportConnectors/transportConnector[#attribute/name == \"test\"] size < 1",
    }

Sample usage with arrays:

    xmlfile_modification{"test" :
      file    => "/etc/activemq/activemq.conf.xml",
      changes => [ "set /beans/broker/transportConnectors/transportConnector[last()+1]/#attribute/name \"tests\"", 
                   "set /beans/broker/transportConnectors/transportConnector[last()+1]/#attribute/value \"tests\""],
      onlyif =>  [ "match /beans/broker/transportConnectors/transportConnector[#attribute/name == \"tests\"] size < 1" ],
    }
   


#### Parameters ####
changes
: Changes which should be applied to the file.  Can be a command or an array of commands.  Augeas-esque syntax.

  Paths are XPATHs. Attributes are matched via #attribute/<ATTR>, or assumed to be text.  Evaluations must be bracketed.

  Commands:

  - set <PATH> "<VALUE>"
  : Sets the path to value, creates it if it does not exist

  - rm <PATH>
  : Removes the path.

  - clear <PATH>
  : Clears the specied path.  Does not create it.

  - ins <PATH> (before|after) <LOCATION>
  : Constructs an element(or elements) using path and inserts it before or after the path specified by location
 
  - sort <PATH> (<VALUE>|text)
  : Sorts all elements that match path by the attribute specified in value.

  Path Functions:

  - last()
  : During initial parsing, substitutes for the index of the last item that matches the expression.

file
: The path to the file to manage.  Must be fully qualified.

  On Windows, the path should include the drive letter and should use `/` as
  the separator character (rather than `\\`).

onlyif
: Constrains application of changes via conditionals.  Augeas-esque syntax.

  Paths are XPATHs.  Attributes are matched via #attribute/<ATTR>, or assumed to be text.  Evaluations must be bracketed.

  Commands:

  - match <PATH> size (==|!=|<|>|<=|>=) <VALUE>
  : Evaluates if a match for the given path meets the conditions specified.

  - get <PATH> (==|!=|<|>|<=|>=) <VALUE>
  : Checks if a path matches a given value under the conditions specified

  Path Functions:

  - last()
  : During initial parsing, substitutes for the index of the last item that matches the expression.
