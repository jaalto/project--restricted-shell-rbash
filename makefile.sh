#!/bin/sh
#
# Description
#
#	Script to create a restricted shell environment using /bin/rbash.
#	Creates a LOGIN NAME if it does not exists. Only root can run this
#	script.
#
# Synopsis
#
#	[test=1] makefile.sh <login name> [allowed commands]

# User globals variables

CHOWN=${CHOWN:-root:root}
HOMEROOT=${HOMEROOT:-/home}
RSHELL=${RSHELL:-/bin/rbash}
COMMANDS=${COMMANDS:-ssh date ls}

# Private global variables

CURDIR=$( cd $(dirname $0) ; pwd )

Warn ()
{
    echo "$*" >&2
}

Run ()
{
    ${test+echo} eval "$@"
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

Main ()
{
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

    Run chown "$CHOWN" .bash* .ssh .ssh/environment
    Run chown "$CHOWN" .
    Run chmod 0644 .bash* .ssh/*
    Run chmod 0750 .
    Run chmod 0755 ssh
    Run chmod ugo-s . .ssh

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
