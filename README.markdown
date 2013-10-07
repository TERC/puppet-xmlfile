# TERC Puppet XMLFile Library #

Provides the xmlfile and xmlfile_modification types and associated providers.

### What? ###
See the type reference.

### Why? ###
While working on a variety of modules I kept running into cases where what I really, really wanted to do was apply augeas 
lenses to a template, but this was problematic.  My first thought was "my kingdom for an array!" which led to the databucket 
library, which is, unfortunately, probably not reliable enough for production or capable of being made reliable enough for 
production.

So, long story short, we wound up writing this.

### How? ###
By extending the Puppet file and using some providers to realize the modifications that exist in the catalog at the time 
of application.

The changes are applied via the XMLLens class, which sort of fakes being augeas.

### License? ###
See the LICENSE file.