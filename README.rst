..  comment: the source is maintained in ReST format.
    Emacs: http://docutils.sourceforge.net/tools/editors/emacs/rst.el
    Manual: http://docutils.sourceforge.net/docs/user/rst/quickref.html

DESCRIPTION
===========

GNU project's Bash running in ``rbash`` mode is a viable choice if you
are trying to somewhat contain trusted users. This project includes
basic files and utility to create a dummy user that only can run
commands of your choice. Project homepage (bugs and source) is at
<http://freecode.com/projects/restricted-shell-rbash>.

How does it work?
-----------------

Bash installation contains ``rbash`` binary which restricts access. See
<http://www.gnu.org/s/bash/manual/html_node/The-Restricted-Shell.html>.
What is left to do is to provide a small set of configuration files to
go with the account and that's pretty much it. The concept is pretty
straight forward but tedious to type all the commans, so this project
simply collects them all to a automatized shell script whi:

1. Create user account, if not yet exists. Set's shell to ``rbash``

2. Copies minimal startup files for Bash and SSH.

2. Make allowed command available user user's ``bin/``directory and points PATH there.

3. Arranges tight permissions on startp files and directories of the created user.

After these steps, the account is hopefully sufficiently locked down.
User cannot edit configuration files, change PATH, run commands
starting with slash, or cd anywhere, so the only commands available to
him are those in ``bin/``.

Warnings
--------

Don't let anyone run commands that allow escaping to shells. Like
editors (``emacs``, ``vi``) or mail programs (``mutt``) etc.

For a real hard security, remember: "Honestly a restricted shells are
depreciated, you should be using tools such as apparmor, selinux,
grsecurity or virtualization as it is rather trivial to break out of
rbash."

REQUIREMENTS
============

1. Environment: Linux only

2. Build: Perl and standard GNU make

3. Run: POSIX ``/bin/sh`` and GNU command line programs

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
    $EDITOR .ssh/authorize_keys

MENU BASED SHELL
================

A popular Perl based menu shell is available at
<http://freecode.com/projects/pshell>. The implementation below does
not require Perl and additional modules, just plain ``/bin/sh``.

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
