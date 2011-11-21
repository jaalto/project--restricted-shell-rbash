#! /bin/sh

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
