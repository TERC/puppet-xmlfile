## terc-xmlfile changelog

Release notes for the terc-xmlfile module

---------------------------------------

2013-11-07 Release 0.3.1
========================

### Summary
This release adds tests, documentation improvements, and better Ruby 1.8.7 compatibility

### Enhancements
- Improved tests.
- Documentation improvements.

### Bugfixes
- Regular Expressions should now work correctly in Ruby 1.8.7

2013-10-10 Release 0.3.0
========================

### Summary
This release adds the add command, this file, aliases for ins/rm, raw processing, conditional improvements, sort behavior bug fixes.

### Features
- Augeas add command equivalent added.
- Aliases for ins and rm(insert and remove, respectively) created so xmlfile_modification more closely mirrors the augeas puppet resource type.

### Enhancements
- Conditional behavior for numerals improved.  If both parts of evaluate are pure digits, a to_i conversion is done before the comparison.
- Documentation improved.

### Bugfixes
- REXML now runs in raw mode for all nodes by default.
- Sort now sorts by node name if third argument is either 0 length or nil.

2013-10-07 Release 0.2.0
========================

### Summary
This is a minor release that warranted a minor version update due to the metaprogramming involved.

#### Detailed Changes
- Automatic importation of docs for inherited attributes on the inherited type.

2013-10-07 Release 0.1.0
========================

### Summary
Initial Release

---------------------------------------