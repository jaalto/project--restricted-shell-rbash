..  comment: the source is maintained in ReST format.
    Emacs: http://docutils.sourceforge.net/tools/editors/emacs/rst.el
    Manual: http://docutils.sourceforge.net/docs/user/rst/quickref.html

Description
===========

GNU project's Bash running in ``rbash`` mode is a viable choice if you
are trying to somewhat contain trusted users. This project includes
basic files and utility to create a dummy user that only can run
command of your choice.

REQUIREMENTS
============

This project is only for Linux systems with GNU tools. Don't try to
use on SunOS Solaris etc. Depends on basic ``/bin/sh`` and standard
utilities only.

USAGE
=====

Simply copy files in this project somewhere and run help ::

    ./makefile.sh --help

Select a user to create (or existing user), who will be locked. To
make sure this is what you want, run in test mode first and nothing is
done but you will see the commands ::

   ./makefile.sh --test dummy

If all looks good, switch to *root* and supply list of commands you
want user to be able to run ::

   ./makefile.sh dummy date ls ssh

Check that everything looks good and make modifications as needed,
like allowing only ssh key based access ::

    cd ~dummy
    .... edit ~dummy/.ssh/authorize_keys

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

Copyright (C) 2010-2012 Jari Aalto <jari.aalto@cante.net>

The material is free; you can redistribute and/or modify it under
the terms of GNU General Public license either version 2 of the
License, or (at your option) any later version.

End of file
