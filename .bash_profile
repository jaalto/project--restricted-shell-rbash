# ~/.bash_profile

umask 007
PATH="%PATH"

if [ -f $HOME/.bashrc ] ; then
    . $HOME/.bashrc
fi

if [ "$TERM" = "ansi" ]; then
    TERM=vt100
    [ -x /usr/bin/resize ] && /usr/bin/resize
fi

# End of file
