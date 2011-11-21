#! /bin/sh
#
#   Copyright information
#
#	Copyright (C) 2011-2012 Jari Aalto
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
# Descriotion
#
#	Edit while-loop to allow user to type recornized commands.
#	Use the program as user's login shell.

PATH="/bin:/usr/bin"
PROMPT="rshell"
HOST=$(hostname)
unset IFS

Prompt ()
{
    pwd=$(pwd)
    echo -n "$LOGNAME@$HOST:$pwd\$ "
}

Error ()
{
    echo "ERROR: Restricted Shell command not allowed: $arg $rest" >&2
}

Main ()
{
    Prompt

    while read arg rest
    do
	case "$arg" in
	    ls | pwd | date | ssh )
		$arg $rest
		;;
	    exit | logout )
		return
		;;
	    *)
		Error
		;;
	esac

	Prompt
    done
}

trap 'exit' 0 1 2 3 9 15
Main

# End of file
