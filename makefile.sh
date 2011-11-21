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
#
#   Description
#
#	See --help. This program must be located in the same directory as the
#	template files used for installation.

AUTHOR="Jari Aalto <jari.aalto@cante.net>"
VERSION="2011.1121.1817"
LICENCE="GPL-2+"
COMMANDS=""

CURDIR=$( cd $(dirname $0) ; pwd )
HOMEROOT=/home
RSHELL=/bin/rbash
CHOWN=root:root

unset test
unset verbose
unset initialize

Echo ()
{
    echo "# $*"
}

Warn ()
{
    Echo "$*" >&2
}

Die ()
{
    Warn "$*"
    exit 1
}

Run ()
{
    if [ "$test" ]; then
	echo "$*"
    else
	eval "$@"
    fi
}

Match ()
{
    case "$2" in
	$1) return 0
	    ;;
	*)  return 1
	    ;;
    esac
}

IsRoot ()
{
    [ "$(id -u -n)" = "root" ]
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

    str=" in $(pwd)"
    [ "$test" ] && str=""
    Echo "[NOTE] Symlinking allowed commands$str"

    if [ "$initialize" ]; then
	Echo "[NOTE] Removing previous commands"
	Run rm -f *
    fi

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

IsMount ()
{
    mount | grep "$1"
}

Chattr ()
{
    if [ ! "$test" ]; then
	mount=$(Run IsMount ":$HOMEROOT")
    fi

    if [ "$mount" ]; then
	Warn "WARN: chattr(1) will fail. Can't change attributes on NFS mount"
	Warn "WARN: run the command manually on the host of $HOMEROOT"
	Warn "$mount"
    fi

    echo "cd ~$LOGIN ; chattr" "$@"
    Run chattr "$@"
}

Help ()
{
    echo "\
SYNOPSIS
	[options] <login name> <list of allowed commands>

DESCRIPTION
	Script to create a restricted shell environment using /bin/rbash.
	Creates a LOGIN NAME if it does not exists. Only root can run this
	script.

OPTIONS
	See manual page for complete set of options.

	-t, --test
	    Show what commands would be run. Do not actually do anything.

	-V, --version
	    Display version.
"
}

Version ()
{
    echo "$VERSION $LICENSE $AUTHOR $URL"
}

Main ()
{
    dummy="$*"				# for debug

    while :
    do
	case "$1" in
	    -d | --homeroot)
		shift
		HOMEROOT="$1"
		if Match -* $HOMEROOT ; then
		    Die "ERROR --homeroot looks like option: $HOMEROOT"
		fi
		shift
		;;
	    -h | --help)
		shift
		Help
		return 0
		;;
	    -i | --init)
		shift
		initialize="initialize"
		;;
	    -o | --chown)
		shift
		CHOWN="$1"
		if Match -* $CHOWN ; then
		    Die "ERROR --chown looks like option: $CHOWN"
		fi
		shift
		;;
	    -s | --shell)
		shift
		RSHELL="$1"
		if Match -* $RSHELL ; then
		    Die "ERROR --shell looks like option: $RSHELL"
		fi
		shift
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
		Warn "[WARN] Unknown option: $1" >&2
		shift
		;;
	      *)
		break
		;;
	esac
    done

    LOGIN="$1"

    if [ ! "$LOGIN" ]; then
	Die "ERROR: Which login name to use for restricted shell?"
    fi

    shift

    if [ ! "$test" ]; then
	if ! IsRoot ; then
	    Die "ERROR: This command can be run only by root"
	fi
    fi

    if [ ! "$RSHELL" ]; then
	Die "ERROR: --shell program not set"
    elif [ ! -x "$RSHELL" ]; then
	Die "ERROR: --shell program does not exists: $RSELL"
    fi

    if ! Match "*:*" $CHOWN ; then
	Die "ERROR --chown is not in format user:group => $CHOWN"
    fi

    if ! Match "/*" $HOMEROOT ; then
	Die "ERROR --homeroot is not an absolute path: $HOMEROOT"
    fi

    if [ "$1" ]; then
	COMMANDS="$*"
    else
	Die "ERROR: Which commands to allow user '$LOGIN' to run?"
    fi

    MakeUser "$LOGIN"
    CopyFiles "$LOGIN"

    Run cd ~"$LOGIN" || return 1

    Run chown "$CHOWN" .
    Run chmod 0750 .
    Run chmod ugo-s .

    Run chown "$CHOWN" .bash*
    Run chmod 0644 .bash*

    touch  .ssh/authorized_keys

    dummy=$(pwd)/
    [ "$test" ] && dummy=""

    Echo "[NOTE] Add keys to $dummy.ssh/authorized_keys"

    Run chown "$CHOWN" .ssh .ssh/*
    Run chmod 0755 .ssh
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
