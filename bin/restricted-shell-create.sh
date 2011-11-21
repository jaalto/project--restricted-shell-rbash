#!/bin/sh
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
#	This is only a redictor which is installed in PATH. It will
#	to call the real $PROGRAM.

set -e

PROGRAM=%PROGRAM

Warn ()
{
    echo "$*" >&2
}

Die ()
{
    Warn "$*"
    exit 1
}

Main ()
{
    case "$PROGRAM" in
	*%*) Die "$0: Setup template error." \
	         "Run Makefile in source distribution."
             ;;
    esac

    if [ ! -x "$PROGRAM" ]; then
	Die "$0: Setup error. Run Makefile in source distribution."
    fi

    dir=$( echo $PROGRAM | sed 's,/[^/]\+$,,' )
    bin=$( echo $PROGRAM | sed 's,.*/,,' )

    cd $dir
    "$bin" "$@"
}

Main "$@"

# End of file
