# TERC Puppet XMLFile Library #

Provides the xmlfile and xmlfile_modification types and associated providers.  

No manifest code is included.

### What? ###
See the type reference.

### Why? ###
While working on a variety of modules I kept running into cases where what I really, really wanted to do was apply augeas 
lenses to a template, but this was problematic.  There were several options for this, none of them good.  I could use a file
concat library, and sandwich augeas and file types that way, have a triggered exec resource, etc.  No matter what we're basically
managing multiple resources when what we really want is just one and some changes.  Just no good way to really deal with it.

My first thought was "my kingdom for an array!" which led to the databucket library, the idea behind which was to do 
collection of resource parameters at catalog compilition into an array, and then use that within the template. This idea, while 
cool, is, unfortunately, probably not reliable enough for production or capable of being made reliable enough for production.  So 
collecting and using virtual or exported data and directly referencing it(IE: in a template) is out.

Hence this, which sidetracks the whole issue. 

### How? ###
By extending the Puppet file type and using some providers collected data is applied as a series of modifications at the moment
of catalog application.  Content is defined as the sourced or templated content + whatever modifications have been linked to
that file.

The changes themeselves are applied via the XMLLens class, which sort of fakes being augeas.

### License? ###
See the LICENSE file.

### Changes ###
####  v0.3.0 ####
- Augeas add command equivalent added.
- Aliases for ins and rm(insert and remove, respectively) created so it functions more like the augeas type.
- Sort behavior fixed so that matching for child node name sorting is triggered on both null and 0-length string args.
- Conditional behavior for numerals improved.  If both parts of evaluate are pure digits, does a to_i on both before comparison.
- Raw processing now on by default.
- Updated this document.

#### v0.2.0 #####
- Automatic importation of docs for inherited attributes.
