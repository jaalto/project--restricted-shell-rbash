#! /bin/bash
#
#   Copyright
#
#       Copyright (C) 2011-2024 Jari Aalto <jari.aalto@cante.net>
#
#   License
#
#       This program is free software; you can redistribute it and/or modify
#       it under the terms of the GNU General Public License as published by
#       the Free Software Foundation; either version 2 of the License, or
#       (at your option) any later version.
#
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#       GNU General Public License for more details.
#
#       You should have received a copy of the GNU General Public License
#       along with this program. If not, see <http://www.gnu.org/licenses/>.
#
#   Description
#
#       See --help. This program must be located in the same directory as the
#       template files used for installation.
#
#   Notes
#
#       The "rbash" behavior is not handled correctly if you su(1) to
#       the account. See <http://bugs.debian.org/411997>. You must use
#       standard login(1).
#
#   Depends (Debian packages)
#
#       util-linux      /usr/bin/getopt [optional]
#       e2fsprogs       /usr/bin/chattr
#       bash            /bin/rbash

AUTHOR="Jari Aalto <jari.aalto@cante.net>"

VERSION="2019.0505.1815"

LICENSE="GPL-2+"
HOMEPAGE=https://github.com/jaalto/project--linux-tmpfs-ramdisk

CURDIR=$(cd $(dirname $0) ; pwd)
HOMEROOT=/home
RSHELL=/bin/rbash
CHOWN=root:root

unset COMMANDS
unset USERGROUP
unset HOMEDIR
unset PASSWD
unset OPT_RSHELL
unset OPT_CHATTR
unset test
unset verbose
unset initialize
unset force

TMPBASE=/tmp/tmp.$(basename $0).$$

# Make sure this is the deault
IFS=$' \t\n'

#######################################################################
#
#       Initial shell check
#
#######################################################################

#   Check correct shell and detect user mistakes like this:
#
#       sh ./program.sh
#
#   The following will succeed under bash, but will give error under sh
#
#   NOTE: In some places the sh is copy of bash (or symlink), but bash
#   would still restrict it to certain features. The simplistic test
#   is not enough. See bash manual and section "INVOCATION".
#
#       eval "[[ 1 ]]" > /dev/null
#
#   The process substitution test will fail under Bash running as
#   "sh" mode.
#
#       eval ": <(:)" > /dev/null

[ "$BASH" = "/usr/bin/bash" ] || [ "$BASH" = "/bin/bash" ] ||
{
    prg="$0"

    # If we did not find ourselves, most probably we were run as
    # 'sh PROGRAM' in which case we are not to be found in PATH.

    if [ -f "$prg" ]; then
        [ -x /bin/bash ] && exec /bin/bash "$prg" ${1:+"$@"}
    fi

    echo "$0 [FATAL] $prg called with wrong shell: needs bash" >&2
    exit 1 ;
}

#######################################################################
#
#       Functions
#
#######################################################################

Tmpfile ()
{
    mktemp $TMPBASE.XXXXXX ||
    {
       echo "$0: [FATAL] Cannnot create temporary file in $TMPBASE" >&2
       exit 1
    }
}

Atexit ()
{
    rm -f "$TMPBASE"*
}

Which ()
{
    local cmd=$1

    local saved="$IFS";
    IFS=":"

    local dir

    for dir in $PATH
    do
        dir=${dir%/}                    # Delete trailing slash

        if [ -x "$dir/$cmd" ]; then
            echo "$dir/$cmd"
            IFS="$saved"
            return 0
        fi
    done

    IFS="$saved"
    return 1
}

MatchGrep ()
{
    echo "$2" | egrep -e "$1" > /dev/null
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

IsOption ()
{
    Match -* "$1"
}

Echo ()
{
    [ "$verbose" ] && echo "# $*"
}

Warn ()
{
    echo "# $*" >&2
}

Die ()
{
    Warn "$*"
    exit 1
}

DieIfOption ()
{
    if Match "-*" $1 ; then
        shift
        Die "ERROR: $*"
    fi
}

Run ()
{
    if [ "$test" ]; then
        echo "$*"
    else
        eval "$@"
    fi
}

DropTrailingSlash ()
{
    echo "$1" | sed "s,/$,,"
}

IsRoot ()
{
    [ "$(id --user --name)" = "root" ]   # TODO: what about "$(id --uid)" = "0"
}

IsUser ()
{
    getent passwd "$1" 2> /dev/null
}

GetHomeDir ()
{
    getent passwd $1 | awk -F: '{print $6}'
}

GetUserGroup ()
{
    #  dummy:x:1001:1001:Restricted user:/home/dummy:/bin/rbash
    #          =========
    getent passwd "$1" 2> /dev/null |
    awk -F: '{ print $3 ":" $4 }'
}

UserShell ()
{
    local login=$1

    [ "$login" ] || return 2
    IsUser "$login" | awk -F: '{print $(NF)}'
}

GeneratePassword ()
{
    perl -e 'print crypt($ARGV[0],q(sa))' ${1:-password}
}

CreateUser ()
{
    local login="$1"

    if IsUser "$login" > /dev/null ; then
        Echo "NOTE: Existing account '$login'."

        if [ "$PASSWD" ]; then
            Echo "NOTE: you must change password manually with passwd(1)"
        fi

        str=$(UserShell $login)

        if [ ! "$str" ]; then
            Echo "WARN: Cannot read current login shell of user '$login'"
        elif Match "*rbash" "$str"; then
            Echo "Good, login shell of user '$login' is $str"
        elif [ "$RSHELL" = "$str" ]; then               # Same, nothing to do
            :
        elif [ "$OPT_RSHELL" ]; then                    # User defined
            Run chsh --shell $RSHELL $login
        elif [ "$force" ]; then
            echo "# NOTE: Changing user's $login shell from $str to $RSHELL"
            Run chsh --shell $RSHELL $login
        else
            echo "[NOTE] Won't change shell from $str." \
                 "Run manually: chsh --shell $RSHELL $login"
        fi

        HOMEDIR=$(GetHomeDir $login)

    else
        Echo "NOTE: adding user '$login'"

        userskel=/tmp/dummy-skel
        HOMEDIR="$HOMEROOT/$login"

        if [ ! -d "$HOMEDIR" ]; then
            useraddopt="--create-home --skel $userskel"
        fi

        Run install --directory --mode=750 "$userskel"

        if [ "$PASSWD" ]; then
            useraddopt="$useraddopt --password '$(GeneratePassword $PASSWD)'"
        fi

        Run useradd \
            --comment "'Restricted user'" \
            ${USERGROUP+--group $USERGROUP} \
            $useraddopt \
            --home "'$HOMEDIR'" \
            --shell $RSHELL \
            "'$login'" || exit $?

       Run rmdir $userskel

    fi
}

MakeRestrictedBin ()
{
    local chownattributes=$1

    Run install --directory --mode=700 bin
    chmod 750 bin
    Run chown "$chownattributes" bin

    local cwd=$(pwd)

    Run cd bin || exit 1

    if [ ! "$test" ]; then
        Echo "Directory $(pwd)"
    fi

    if [ "$initialize" ]; then
        Echo "NOTE: Removing previous commands"
        Run rm $verbose -f *
    fi

    Echo "Symlinking allowed commands"

    local cmd debug

    for cmd in $COMMANDS
    do
        debug="$cmd"

        case "$cmd" in
            /*) path="$cmd"
                cmd=$(echo $cmd | sed 's,.*/,,')
                ;;

             */*)
                Warn "ERROR: Not an absolute path, skipped: $cmd"
                continue
                ;;

             *) path=$(which $cmd)
                ;;
        esac

        [ "$path" ] && Run ln $verbose --force --symbolic "$path" "$cmd"
    done

    cd "$cwd" || exit 1
}

SetPath ()
{
    local path="$(pwd)/bin"

    local file

    for file in .bash_profile .ssh/environment
    do
        [ -f "$file" ] || continue

        Run sed --in-place "s,%PATH,$path," "$file"
    done
}

CopyFiles ()
{
    local dir="$1"

    umask 022

    cd "$CURDIR" || exit 1

    Echo "Copying setup files"

    local elt

    for elt in .[a-z]*
    do
        # This directory may be in version control. Skip

        case "$elt" in
            .git* | .bzr* | .hg* | *.svn ) continue ;;
        esac

        if [ ! "$test" ]; then
            if [ "$force" ]; then
                :   # Skip
            elif [ -f "$dir/$elt" ] || [ -d ~"$dir/$elt" ] ; then
                Warn "WARN: Not overwriting without" \
                     "--force file: $dir/$elt"
                continue
            fi
        fi

        if [ -d "$elt" ]; then
            Run cp $verbose --recursive "$elt" "dir1"/
        else
            Run cp $verbose "$elt" "$dir/$elt"
        fi
    done
}

IsMount ()
{
    mount | grep "$1"
}

Chattr ()
{
    [ "$OPT_CHATTR" ] || return 0

    if [ ! "$test" ]; then
        mount=$(Run IsMount ":$HOMEROOT")
    fi

    if [ "$mount" ]; then
        Warn "WARN: chattr(1) will fail. Can't change" \
             "attributes on NFS mount"
        Warn "WARN: run the command manually on the host of $HOMEROOT"
        Warn "$mount"
    fi

    Echo "cd $HOMEDIR ; chattr" "$@"
    Run chattr "$@"
    unset mount
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

        The list of allowed commands must be on standard PATH
        (/usr/bin:/usr/loca/bin) or listed with full path names.

OPTIONS
        See manual page for complete set of options. This is an exerpt only:

        -D, --debug
            Activate shell debug option.

        -f, --force
            Allow destructive changes, like overwriting files while
            copying bash startup to user's home directory.

        -i, --init
            Clean initialization. Delete all previous commands from user's
            bin/ directory before creating symlinks to the allowed
            commands.

        -t, --test
            Show what commands would be run. Do not actually do anything.

        -V, --version
            Display version.

BUGS

        Due to lack of available tools in POSIX shell, combining short
        options is not supported; .e.g. -fi. All options must be
        give separately using spaces: -f -i."
}

Version ()
{
    echo "$VERSION $LICENSE $AUTHOR $HOMEPAGE"
}

#######################################################################
#
#       Main
#
#######################################################################

Main ()
{
    dummy="$*"                          # for debug

    if  Which getopt > /dev/null ; then

        # What getopt(1) does is to allow user to cmbine options (-vh).
        # It splits them apart (see eval) in form "-v -h" so that they
        # can be processed.

        tmpopt=$(getopt \
        --shell bash \
        --name "$0.Main($VERSION restricted-shell-create)" \
        --long attributes,homeroot:,debug,force,group:,help,init,chown,passwd,shell,test,verbose,version \
        --option "ad:Dfg:hiops:tvV" -- "$@" \
        )

        if [ "$?" != "0" ]; then
            for i in "$@"
            do
                case "$i" in
                    -[a-z][a-z])
                        Die "FATAL: No getopt(1) in PATH to parse" \
                            "combined options ($i); use separate options"
                        ;;
                esac
            done

            unset i
        fi

        eval set -- "$tmpopt"
        unset tmpopt
    fi

    # POSIX shell statements to parse options

    while :
    do
        case "$1" in
            -a | --attributes)
                OPT_CHATTR="opt-chattr"
                ;;
            -d | --homeroot)
                shift
                HOMEROOT="$1"
                DieIfOption $HOMEROOT \
                    "--homeroot looks like an option: $HOMEROOT"
                shift
                ;;
            -D | --debug)
                shift
                set -x
                ;;
            -f | --force)
                shift
                force="force"
                ;;
            -g | --group)
                shift
                USERGROUP="$1"
                DieIfOption $USERGROUP \
                    "--group looks like an option: $USERGROUP"
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
                DieIfOption $CHOWN "--chown looks like an option: $CHOWN"
                shift
                ;;
            -p | --passwd)
                shift
                PASSWD="$1"
                DieIfOption $PASSWD "--passwd looks like an option: $PASSWD"
                shift
                ;;
            -s | --shell)
                shift
                OPT_RSHELL="opt-rshell"
                RSHELL="$1"
                DieIfOption $RSHELL "--shell looks like an option: $RSHELL"
                shift
                ;;
            -t | --test)
                shift
                test="test"
                ;;
            -v | --verbose)
                shift
                verbose="--verbose"
                ;;
            -V | --version)
                shift
                Version
                return 0
                ;;
             --)
                shift
                break
                ;;
             -*)
                Warn "[WARN] Unknown option: $1"
                return 1
                ;;
              *)
                break
                ;;
          esac
    done

    LOGIN="$1"

    # .... verify usage ...................................................

    if [ ! "$LOGIN" ]; then
        Die "ERROR: Missing login name for restricted shell. See --help"
    fi

    shift

    if [ ! "$test" ]; then
        if ! IsRoot ; then
            Die "ERROR: This utlity can only be run by root"
        fi
    fi

    if [ "$LOGIN" ]; then
        list=""

        # Do some sanity checks

        for elt in "$@"
        do
            MatchGrep "^[ ]+$" "$elt" && continue

            case "$elt" in
                *\ *)
                    Warn "WARN: Ignoring command with space: '$elt'"
                    ;;
                cd)
                    Warn "WARN: Ignoring command 'cd'. See rbash(1)"
                    ;;
                */) Warn "WARN: Ignoring command: '$elt'"
                    ;;
                */*)Warn "WARN: Ignoring command with relative path: '$elt'"
                    ;;
                 *) list="$list $elt"
                    ;;
            esac
        done

        Echo "NOTE: Using command set: $list"

        COMMANDS="$list"

        unset elt
        unset list
    fi

    if [ ! "$COMMANDS" ]; then
        Warn "WARN: no list of commands to allowed by '$LOGIN'"
    fi

    if [ ! "$RSHELL" ]; then
        Die "ERROR: --shell program not set"
    elif [ ! -x "$RSHELL" ]; then
        Die "ERROR: --shell program does not exist: $RSHELL"
    elif ! MatchGrep "^/[^/]+/[-_.a-zA-Z0-9]+$" "$RSHELL" ; then
        Die "ERROR: --shell path name is invalid: '$RSHELL'"
    fi

    if ! Match "*[a-z]:[a-z]*" "$CHOWN" ; then
        Die "ERROR: --chown is not in format user:group => $CHOWN"
    fi

    if ! Match "/*" $HOMEROOT ; then
        Die "ERROR: --homeroot is not an absolute path: $HOMEROOT"
    fi

    HOMEROOT=$(DropTrailingSlash $HOMEROOT)

    # .... DO IT ..........................................................

    CreateUser "$LOGIN"
    CopyFiles "$HOMEDIR"

    Run cd "$HOMEDIR" || return 1

    chown=$(GetUserGroup "$LOGIN")

    if [ ! "$chown" ]; then
        Die "INTERNAL ERROR: Can't read user:group." \
            "Run program option --debug"
    fi

    MakeRestrictedBin "$chown"

    # .... bash ...........................................................

    Run chown "$chown" .
    Run chmod 0750 .
    Run chmod ugo-s .

    Run chown "$CHOWN" .bash*
    Run chmod 0644 .bash*

    umask 077

    # Allow only appending to the .bash_history file

    Run Chattr -a .bash_history 2> /dev/null # Can't chown without this
    Run chown "$CHOWN" .bash_history

    # Allow appending to the file
    Run Chattr +a .bash_history

    # .... ssh ............................................................

    cwd=
    [ "$test" ] || cwd="$(pwd)/"

    Echo "NOTE: Add keys to $cwd.ssh/authorized_keys"

    Run chown root:root .ssh .ssh/*
    Run chmod 0750 .ssh
    Run chmod ugo-s .ssh
    Run chmod 0640 .ssh/*

    Run touch  .ssh/authorized_keys

    local file

    for file in .ssh/authorized_keys .ssh/id*
    do
        [ -f "$file" ] && Run chmod 0600 "$file"
    done

    touch .shosts
    Run chown root:root .shosts
    Run chmod 0600 .shosts

    # .... other ..........................................................

    touch .rhosts
    Run chown root:root .rhosts
    Run chmod 0600 .rhosts

    SetPath
}

# Nubers are not POSIX: 0 1 2 5 15
trap Atexit EXIT HUP INT TRAP TERM

Main "$@"

# End of file
