#!/bin/sh
#
# To create restricted shell

Run ()
{
    ${test+echo} eval "$@"
}

Main ()
{
    LOGIN=$1

    if [ ! "$LOGIN" ]; then
	echo "ERROR: Which login name to create for restricted shell?"
	return 1
    fi

    Run useradd -d /home/dummy -s /bin/rbash dummy

    Run mkdir -p /usr/local/bin/restricted

    Run cd /usr/local/bin/restricted

    for cmd in ls date ssh
    do
	path=$(which $cmd)

	[ "$path" ] && Run ln -s $path $cmd
    done

    Run cd ~$LOGIN || return 1

    Run mkdir .ssh
    Run "echo PATH=/usr/local/bin/restricted > .ssh/environment"

    Run touch .bashrc .bash_logout
    Run "echo PATH=/usr/local/bin/restricted > .bash_profile"

    Run chown root:root .bash* .ssh .ssh/environment
    Run chown root:root .
    Run chmod 755 . .bash* .ssh/*
}

Main "$@"

# End of file
