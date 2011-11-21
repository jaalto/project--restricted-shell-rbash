# ~/.bashrc

set +a # Do not export variables and functions
set -f # Disable pathname expansion
set +h # Don't cache commands
set +k # Disable automatic envvar use in commands
set +m # Disable job control
set -p # Priviledged mode
set +B # No brace expansion
set +H # No history expansions
set +o histexpand # No history expansions

shopt -u \
 dotglob \
 expand_aliases \
 extglob \
 extquote \
 histreedit \
 hostcomplete \
 mailwarn \
 progcomp \
 promptvars \
 xpg_echo

# End of file
