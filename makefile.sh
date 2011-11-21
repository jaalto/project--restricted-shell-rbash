#!/bin/sh
#
# To create restricted shell

pwd=$( cd $(dirname $0) ; pwd )

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
	Run useradd -d /home/dummy -s /bin/rbash "$1"
	mkdir -p "/home/$1"
    fi
}

MakeBin ()
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

Copy ()
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
    mount=$(mount | grep ':/home')

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
    MakeBin
    Copy "$LOGIN"

    Run cd ~$LOGIN || return 1

    Run chown root:root .bash* .ssh .ssh/environment
    Run chown root:root .
    Run chmod 0644 .bash* .ssh/*
    Run chmod 0755  . .ssh
    Run chmod ugo-s . .ssh

    umask 077

    Run chown root:root .bash_history
    # Allow appending to the file
    Run Chattr +a .bash_history

    Run chown root:root .rhosts .shosts
    Run chmod 0600 .rhosts .shosts
}

Main "$@"

# End of file
