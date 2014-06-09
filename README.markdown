TERC Puppet XMLFile Library
=======

####Table of Contents

1. [Overview - What is the xmlfile module?](#overview)
2. [Why - Reasoning for developing this module ](#why?)
3. [Implementation - Summary of the under the hood implementation of the module ](#implementation)
4. [Limitations - Known issues and limitations of the implementation ](#limitations)
5. [Release Notes - Notes on the most recent updates to the module](#release-notes)

Overview
--------

The xmlfile module provides the xmlfile and xmlfile_modification types as well as associated providers.

No manifest code is included.  This is pretty much pure ruby code for inclusion in other modules.

Why?
--------
While working on a variety of modules I kept running into cases where what I really, really wanted to do was apply augeas 
lenses to a template, but this was problematic.  There were several options for this, none of them good.  I could use a file
concat library, and sandwich augeas and file types that way, have a triggered exec resource, etc.  No matter what we're basically
managing multiple resources when what we really want is just one and some changes.  Just no good way to really deal with it.

My first thought was "my kingdom for an array!" which led to the databucket library, the idea behind which was to do 
collection of resource parameters at catalog compilition into an array, and then use that within the template. This idea, while 
cool, is, unfortunately, probably not reliable enough for production or capable of being made reliable enough for production.  So 
collecting and using virtual or exported data and directly referencing it(IE: in a template) is out.

Hence this, which sidetracks the whole issue. 

Implementation
--------
By extending the Puppet file type and using some providers we can merge templated or sourced content and modifications and
have puppet treat this content as if it had been passed directly.

The changes themeselves are applied via the XmlLens class, which fakes being augeas.  This is accomplished via the standard
ruby REXML library.  Upshot of this is we can add in things like sorting.

Limitations
--------
I don't have a complete windows puppet kit and so while we extend the windows provider and it should work, I can't actually 
test it.

Property fix is called via send on object creation.  This may create a security issue when a file is first created if the properties are
not correctly set, although this should get fixed on the next puppet run.

The augeas implementation is incomplete and not exact.  If you notice an issue or unexpected behavior, please open an issue.

REXML has some limitations and quirks of its own.  <, &, and > if by themselves will be automagically converted to 
&amp;lt; &amp;amp; and &amp;gt; and there's no way to turn this off.  Content is otherwise put into raw mode and so it shouldn't be
messed with.

Release Notes
--------
#### v0.4.0
- Fixes issues introduced by deprecation of :parent and type inheritance.

####  v0.3.1
- Regular expressions tweaked for 1.8.7 compatibility.

####  v0.3.0
- Augeas add command equivalent added.
- Aliases for ins and rm(insert and remove, respectively) created so it functions more like the augeas type.
- Sort behavior fixed so that matching for child node name sorting is triggered on both null and 0-length string args.
- Conditional behavior for numerals improved.  If both parts of evaluate are pure digits, does a to_i on both before comparison.
- Raw processing now on by default.
- Updated this document.

#### v0.2.0
- Automatic importation of docs for inherited attributes.
