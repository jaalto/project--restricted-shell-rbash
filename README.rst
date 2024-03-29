..  comment: the source is maintained in ReST format.
    Emacs: http://docutils.sourceforge.net/tools/editors/emacs/rst.el
    Manual: http://docutils.sourceforge.net/docs/user/rst/quickref.html

DESCRIPTION
===========

Utility to create restricted shell, to jail, account using Bash in rbash mode.

GNU project's Bash running in ``rbash`` mode is a viable choice if you
are trying to somewhat contain semi-trusted users. This project includes
basic files and utility to create a dummy user that only can run
commands of your choice. Useful for setting up tightly confined secure
accounts that allow minimum access to restricted set of commands.

How does it work?
-----------------

Bash installation contains ``rbash`` binary which can restrict access.
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

3. Run: Bash for ``/bin/rbash``, POSIX ``/bin/sh`` and GNU command
   line programs, e2fsprogs package for ``/usr/bin/chattr`` and
   optionally util-linux package for ``/usr/bin/getopt``

USAGE
=====

Login to the server that distributes ``/home`` directories, switch to
administrator *root*, select a login name (or supply existing login),
which will be locked. Use Option --test to see what would happen ::

    ./makefile.sh -v --init --force --test dummy date ls ssh
                                           |     |
                                           |     List of allowed commands
                                        User's login name

    -f, --force
        Allow destructive changes, like overwriting files in user's account.
	Used prmarily when command is repeated so that new set of commands
	can be defined freely.

    -i, --init
        Clean initialization. Delete all previous commands from user's
        bin/ directory before creating symlinks to the allowed
        commands.

    -v, --verbose
        Display verbose messages.

After the initialization, you might want to check how the account works: ::

    # set password
    passwd dummy
      Enter new UNIX password: xxx
      Retype new UNIX password: xxx

    # Test restricted shell by logging to an account. It's not possible
    # to use su(1) here. See manual page of restricted-shell-create(5)
    # why su(1) does not work.
    login dummy
      password: xxxxxx

    # See what you can do as user dummy?
    $ ls
    $ date
    $ perl -V
    -rbash: perl: command not found

MENU BASED SHELL
================

The implementation presented here does not require Perl and additional
modules, just plain POSIX shell ``/bin/sh``.

Directory ``bin/`` contains a very simple menu script that allows
running only defined set of commands. You could use it instead of
previous ``rbash`` approach by setting user's shell to the script.
This script is experimental and provided "as is". Use your judgement
if you want to use this approach ::

   # Create user "dummy"
   ./makefile.sh dummy

   # Install command menu based "restricted shell"
   install -D -m 700 bin/rshell.sh ~dummy/bin/rshell

   # Edit commands in case-statement of Main() function
   $EDITOR ~dummy/bin/rshell

Note: See also a Perl based menu shell at
<http://freecode.com/projects/pshell> and
<https://sourceforge.net/projects/psydev/>.

COPYRIGHT AND LICENSE
=====================

Copyright (C) 2011-2024 Jari Aalto <jari.aalto@cante.net>

This project is free; you can redistribute and/or modify it under
the terms of GNU General Public license either version 2 of the
License, or (at your option) any later version.

Project homepage (bugs and source) is at
https://github.com/jaalto/project--restricted-shell-rbash

.. End of file
