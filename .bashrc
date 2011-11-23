# ~/.bashrc

set +a			# Do not export variables and functions
set -f 			# Disable pathname expansion
set +h 			# Don't cache commands
set +k 			# Disable automatic envvar use in commands
set +m 			# Disable job control
set -p 			# Priviledged mode
set +B 			# No brace expansion
set +H 			# No history expansions
set +o histexpand	# No history expansions

shopt -u dotglob	# Do not consider dot-files for pathname expansion
shopt -u expand_aliases # Do not expand aliases
shopt -u extglob	# Do not use extended pattern matching
shopt -u extquote	# Do not use $'string'
shopt -u histreedit	# Do not edit failed history substitution.
shopt -u hostcomplete	# Do not attempt hostname completion
shopt -u mailwarn	# Do not check mail
shopt -u progcomp	# Do not use  programmable completion facilities
shopt -u promptvars	# Do not handle string expansions
shopt -u sourcepath	# Do not use PATH to search files for the source cmd
shopt -u xpg_echo	# Do not expand backslash escaped in echo(1)

# End of file
