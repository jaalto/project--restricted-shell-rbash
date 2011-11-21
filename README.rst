..  comment: the source is maintained in ReST format.
    Emacs: http://docutils.sourceforge.net/tools/editors/emacs/rst.el
    Manual: http://docutils.sourceforge.net/docs/user/rst/quickref.html

Description
===========

GNU project's Bash running in ``rbash`` mode is a viable choice if you
are trying to somewhat contain trusted users. This project includes
basic files and utility to create a dummy user that only can run
commands of your choice.

REQUIREMENTS
============

This project is only for Linux systems with GNU tools. Don't try to
use on SunOS Solaris etc. Depends on basic ``/bin/sh`` and standard
utilities only.

USAGE
=====

Simply copy files in this project somewhere and read usage ::

    ./makefile.sh --help

Select a user to create (or an existing user), who will be locked. To
see what command would be run, make a test run ::

   ./makefile.sh --test dummy

If all looks good, switch to *root* and supply list of commands you
want user to be able to run ::

   ./makefile.sh dummy date ls ssh

Check that everything looks good and make modifications as needed,
like allowing only ssh key based access ::

    cd ~dummy
    .... edit ~dummy/.ssh/authorize_keys

MENU BASED SHELL
================

A popular perl based menu shell is available at
<http://freecode.com/projects/pshell>. The code below is simple and
does not require Perl and additional Perl Modules, just plain ``/bin/sh``.

Directory ``bin/`` contains a very simple menu based script that
allows running only selected commands. You could use it instead of
previous ``rbash`` approach by setting user's shell to the script ::

   # Create user and needed files
   ./makefile.sh dummy date

   # Install command menu based "restricted shell"
   install -D -m 700 bin/rshell.sh ~dummy/bin/rshell

   # Edit commands in Main() case-statement
   $EDITOR ~dummy/bin/rshell

   # Change user's shell
   chsh -s $(cd ~dummy; echo $(pwd)/bin/rshell) dummy

This feature is experimental and I'm not exactly convinced that shell
scrips are safe anough to be used as menu shells. Use your judgement
if you really want to use method below.

NOTES
=====

Don't let anyone run commands that allow escaping to shells. Like
editors (``emacs``, ``vi``) or mail programs (``mutt``) etc.

For real hard security, remember: "Honestly a restricted shells are
depreciated, you should be using tools such as apparmor, selinux,
grsecurity or virtualization as it is rather trivial to break out of
rbash."

REFERENCES
==========

Please read article
http://www.symantec.com/connect/articles/restricting-unix-users to
understand which method would be suitable for your threat level.

Copyright and License
=====================

Copyright (C) 2011-2012 Jari Aalto <jari.aalto@cante.net>

The material is free; you can redistribute and/or modify it under
the terms of GNU General Public license either version 2 of the
License, or (at your option) any later version.

End of file
