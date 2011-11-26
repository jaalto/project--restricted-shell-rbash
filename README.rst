..  comment: the source is maintained in ReST format.
    Emacs: http://docutils.sourceforge.net/tools/editors/emacs/rst.el
    Manual: http://docutils.sourceforge.net/docs/user/rst/quickref.html

DESCRIPTION
===========

Utility to create restricted shell account using Bash in rbash mode.

GNU project's Bash running in ``rbash`` mode is a viable choice if you
are trying to somewhat contain trusted users. This project includes
basic files and utility to create a dummy user that only can run
commands of your choice. Useful for setting up tightly confined secure
accounts that allow minimum access to restricted set of commands.

Project homepage (bugs and source) is at
<http://freecode.com/projects/restricted-shell-rbash>.

How does it work?
-----------------

Bash installation contains ``rbash`` binary which restricts access.
See
<http://www.gnu.org/s/bash/manual/html_node/The-Restricted-Shell.html>.
What is left to do is to provide a small set of configuration files to
go with the account. The concept is pretty straight forward but it is
tedious to type all the commands. This project automates the steps to:

1. Create a user account, provided it does not exist. Set login shell to ``rbash``

2. Copy minimal startup files (Bash, SSH).

2. Symlink allowed commands to user's ``bin/`` directory and point PATH there.

3. Set tight permissions for the account directory and its files.

After these steps, the account is hopefully sufficiently locked down.
User cannot edit configuration files, change PATH, run commands
starting with slash, or cd anywhere, so the only commands available to
him are those in ``bin/``.

REQUIREMENTS
============

1. Environment: Linux only

2. Build: Perl and standard GNU make

3. Run: Bash for rbash, POSIX ``/bin/sh`` and GNU command line programs

USAGE
=====

Login to the server that distributes ``/home`` directories, switch to
administrator *root*, select a login name (or supply existing login),
which will be locked. Use Option --test to see what would happen ::

   ./makefile.sh --test dummy date ls ssh
                        |     |
			|     List of allowed commands
			User's login name

MENU BASED SHELL
================

A popular Perl based menu shell is available at
<http://freecode.com/projects/pshell>. The implementation below does
not require Perl and additional modules, just plain ``/bin/sh``.

Directory ``bin/`` contains a very simple menu shell script that
allows running only defined commands. You could use it instead of
previous ``rbash`` approach by setting user's shell to the script.
This script is experimental and provided "as is". Use your judgement
if you want to use this approach ::

   # Create user "dummy"
   ./makefile.sh dummy

   # Install command menu based "restricted shell"
   install -D -m 700 bin/rshell.sh ~dummy/bin/rshell

   # Edit commands in case-statement of Main() function
   $EDITOR ~dummy/bin/rshell

   # Change user's shell
   chsh --shell $(cd ~dummy; echo $(pwd)/bin/rshell) dummy

Copyright and License
=====================

Copyright (C) 2011-2012 Jari Aalto <jari.aalto@cante.net>

This project is free; you can redistribute and/or modify it under
the terms of GNU General Public license either version 2 of the
License, or (at your option) any later version.

End of file
