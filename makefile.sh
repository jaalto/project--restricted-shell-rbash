#!/bin/sh
#
#   Copyright
#
#	Copyright (C) 2011 Jari Aalto <jari.aalto@cante.net>
#
#   License
#
#	This program is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation; either version 2 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with this program. If not, see <http://www.gnu.org/licenses/>.

# User globals variables

CHOWN=${CHOWN:-root:root}
HOMEROOT=${HOMEROOT:-/home}
RSHELL=${RSHELL:-/bin/rbash}
COMMANDS=${COMMANDS:-ssh date ls}

# Private global variables

AUTHOR="Jari Aalto <jari.aalto@cante.net>"
VERSION="2011.1121.1016"
LICENCE="GPL-2+"

CURDIR=$( cd $(dirname $0) ; pwd )
unset test
unset verbose

Warn ()
{
    echo "$*" >&2
}

Run ()
{
    if [ "$test" ]; then
	echo "$*"
    else
	eval "$@"
    fi
}

IsUser ()
{
    getent passwd "$1" > /dev/null 2>&1
}

MakeUser ()
{
    if ! IsUser "$1" ; then
	# Don't use -m option because it would copy skeleton files.
	Run useradd -d "$HOMEROOT/dummy" -s "$RSHELL" "$1"
	Run mkdir -p "$HOMEROOT/$1"
    fi
}

MakeRestrictedBin ()
{
    Run install -d -m 755 bin
    Run chown "$CHOWN" bin

    pwd=$(pwd)
    Run cd bin || exit 1

    echo "[NOTE] Alowed commands in $(pwd)"

    for cmd in $COMMANDS
    do
	case "$cmd" in
	    /*) path="$cmd"
		cmd=$( echo $cmd | sed 's,.*/,,' )
		;;

	     */*)
		Warn "ERROR: Not an absolute path, skipped: $cmd"
		continue
		;;

	     *) path=$(which $cmd)
		;;
	esac

	[ "$path" ] && Run ln --verbose --force -s "$path" "$cmd"
    done

    cd "$pwd" || exit 1
}

SetPath ()
{
    path="$(pwd)/bin"

    for file in .bash_profile .ssh/environment
    do
	[ -f "$file" ] || continue

	Run sed --in-place "s,%PATH,$path," "$file"
    done
}

CopyFiles ()
{
    umask 022

    cd "$CURDIR" || exit 1

    for elt in .[a-z]*
    do
	# This directory may be in version control. Skip

	case "$elt" in
	    .git* | .bzr* | .hg* | *.svn ) continue ;;
	esac

	if [ -d "$elt" ]; then
	    Run cp --verbose -r "$elt" ~"$1"/
	else
	    Run cp --verbose "$elt" ~"$1"/
	fi
    done
}

MountWarning ()
{
    mount=$(mount | grep ":$HOMEROOT")

    if [ "$mount" ]; then
	Warn "WARN: Can't change attributes on NFS mount"
	Warn "$mount"
    fi
}

Chattr ()
{

    Run MountWarning
    echo "$(pwd): chattr" "$@"
    Run chattr "$@"
}

Help ()
{
    echo "\
SYNOPSIS

	$0 [options] <login name> [allowed commands]

OPTIONS
	-h, --help
	    Display short help.

	-t, --test
	    Show only command to run. Do not actually do anything.

	-v, --verbose
	    Be verbose.

	-V, --version
	    Display version.

DESCRIPTION

	Script to create a restricted shell environment using /bin/rbash.
	Creates a LOGIN NAME if it does not exists. Only root can run this
	script.
"
}

Version ()
{
    echo "$VERSION $LICENSE $AUTHOR $URL"
}

Main ()
{
    while :
    do
	case "$1" in
	    -h | --help)
		shift
		Help
		return 0
		;;
	    -t | --test)
		shift
		test="test"
		;;
	    -v | --verbose)
		shift
		verbose="verbose"
		;;
	    -V | --version)
		shift
		Version
		return 0
		;;
	     -*)
		echo "Unknown option: $1" >&2
		shift
		;;
	      *)
		break
		;;
	esac
    done

    LOGIN=$1
    shift

    if [ ! "$LOGIN" ]; then
	Warn "ERROR: Which login name to use for restricted shell?"
	return 1
    fi

    if [ ! "$test" ]; then
	if [ "$(id -u -n)" != "root" ]; then
	    Warn "ERROR: This file must be run by root"
	    return 1
	fi
    fi

    if [ "$1" ]; then
	COMMANDS="$*"
    fi

    MakeUser "$LOGIN"
    CopyFiles "$LOGIN"

    Run cd ~$LOGIN || return 1

    Run chown "$CHOWN" .
    Run chmod 0750 .
    Run chmod ugo-s .

    Run chown "$CHOWN" .bash*
    Run chmod 0644 .bash*

    touch  .ssh/authorized_keys
    echo "[NOTE] Add keys to $(pwd)/.ssh/authorized_keys"
    Run chown "$CHOWN" .ssh .ssh/*
    Run chmod 0755 .ossh
    Run chmod ugo-s .ssh
    Run chmod 0644 .ssh/*


    umask 077

    Run chattr -a .bash_history 2> /dev/null # Can't chown without this
    Run chown "$CHOWN" .bash_history
    # Allow appending to the file
    Run Chattr +a .bash_history

    Run chown "$CHOWN" .rhosts .shosts
    Run chmod 0600 .rhosts .shosts

    MakeRestrictedBin
    SetPath
}

Main "$@"

# End of file
