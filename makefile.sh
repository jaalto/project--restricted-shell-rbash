#!/bin/sh
#
# Script to create a restricted shell environment using /bin/rbash. Creates
# a LOGIN NAME if it does not exists. Only root can run this script.
#
# Synopsis: [RSHELL=shell] [HOMEROOT=dir] [test=1] makefile.sh <login name>

# User globals variables

CHOWN=${CHOWN:-root:root}
HOMEROOT=${HOMEROOT:-/home}
RSHELL=${RSHELL:-/bin/rbash}

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
    [ -d /usr/local/bin/restricted ] && return 0

    Run mkdir -p /usr/local/bin/restricted

    Run cd /usr/local/bin/restricted

    for cmd in ls date ssh
    do
	path=$(which $cmd)

	[ "$path" ] && Run ln -s $path $cmd
    done
}

CopyFiles ()
{
    umask 022

    for elt in .[a-z]*
    do
	case "$elt" in
	    .git*) continue ;;
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
    mount=$(mount | grep ':$HOMEROOT')

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

    MakeUser "$LOGIN"
    MakeRestrictedBin

    cd "$CURDIR" || return 1
    CopyFiles "$LOGIN"

    Run cd ~$LOGIN || return 1

    Run chown "$CHOWN" .bash* .ssh .ssh/environment
    Run chown "$CHOWN" .
    Run chmod 0644 .bash* .ssh/*
    Run chmod 0755  . .ssh
    Run chmod ugo-s . .ssh

    umask 077

    Run chown "$CHOWN" .bash_history
    # Allow appending to the file
    Run Chattr +a .bash_history

    Run chown "$CHOWN" .rhosts .shosts
    Run chmod 0600 .rhosts .shosts
}

Main "$@"

# End of file
