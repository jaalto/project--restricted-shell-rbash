# Disable options

set \
 +a \ # Do not export variables and functions
 -f \ # Disable pathname expansion
 +h \ # Don't cache commands
 +k \ # Disable automatic envvar use in commands
 +m \ # Disable job control
 +o histexpand \ # No history expansions
 -p \ # Priviledged mode
 +B \ # No brace expansion
 +H \ # No history expansions

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
