#!/usr/bin/env zsh

##
# zsh-system-clipboard
#
# @author Kutsan Kaplan <me@kutsankaplan.com>
# @license GPL-3.0
# @version v0.6.0
##

function _zsh_system_clipboard() {
	function error() {
		echo -e "\n\n  \033[41;37m ERROR \033[0m \033[01mzsh-system-clipboard:\033[0m $@\n" >&2
	}

	function suggest_to_install() {
		error "Could not find any available clipboard manager. Make sure you have \033[01m${@}\033[0m installed."
	}

	local -A CLIPBOARD

	function () {
		case "$OSTYPE" {
			darwin*)
				if ((hash pbcopy && hash pbpaste) 2>/dev/null) {
					typeset -g CLIPBOARD[set]='pbcopy'
					typeset -g CLIPBOARD[get]='pbpaste'
				} else {
					suggest_to_install 'pbcopy, pbpaste'
				}
				;;

			linux-android*)
				if ((hash termux-clipboard-set && hash termux-clipboard-get) 2>/dev/null) {
					typeset -g CLIPBOARD[set]='termux-clipboard-set'
					typeset -g CLIPBOARD[get]='termux-clipboard-get'
				} else {
					suggest_to_install 'Termux:API (from Play Store), termux-api (from apt package)'
				}
				;;

			linux*|freebsd*)
				if (hash xclip 2>/dev/null) {
					local clipboard_selection

					case $ZSH_SYSTEM_CLIPBOARD_XCLIP_SELECTION {
						PRIMARY)
							clipboard_selection='PRIMARY'
							;;

						CLIPBOARD)
							clipboard_selection='CLIPBOARD'
							;;

						*)
							if [[ $ZSH_SYSTEM_CLIPBOARD_XCLIP_SELECTION != '' ]] {
								error "\033[01m$ZSH_SYSTEM_CLIPBOARD_XCLIP_SELECTION\033[0m is not a valid value for \$ZSH_SYSTEM_CLIPBOARD_XCLIP_SELECTION. Please assign either 'PRIMARY' or 'CLIPBOARD'."

							} else {
								clipboard_selection='CLIPBOARD'
							}
							;;
					}

					typeset -g CLIPBOARD[set]="xclip -sel $clipboard_selection -in"
					typeset -g CLIPBOARD[get]="xclip -sel $clipboard_selection -out"
				} else {
					suggest_to_install 'xclip'
				}
				;;

			*)
				error 'Unsupported system.'
				;;
		}
	}

	function sub_set() {
		if [[ "$ZSH_SYSTEM_CLIPBOARD_TMUX_SUPPORT" != '' ]] {
			# Set also tmux clipboard buffer if tmux available.
			if (hash tmux &>/dev/null && [[ "$TMUX" != '' ]]) {
				tmux set-buffer -- "$@"
			}
		}

		echo -E "$@" | eval "${CLIPBOARD[set]}"
	}

	function sub_get() {
		echo -E $(eval ${CLIPBOARD[get]})
	}

	local subcommand=${1:-''}

	case "$subcommand" {
		set)
			shift
			sub_${subcommand} "$*"

			return true
			;;

		get)
			shift
			sub_${subcommand}

			return true
			;;

		*)
			return false
	}
}

# Copy selection.
function zsh-system-clipboard-yank() {
	zle vi-yank
	_zsh_system_clipboard set "$CUTBUFFER"
}
zle -N zsh-system-clipboard-yank

# Copy whole line.
function zsh-system-clipboard-yank-whole-line() {
	zle vi-yank-whole-line
	_zsh_system_clipboard set "$CUTBUFFER"
}
zle -N zsh-system-clipboard-yank-whole-line

# Paste after cursor.
function zsh-system-clipboard-put-after() {
	local CLIPBOARD=$(_zsh_system_clipboard get)

	BUFFER="${BUFFER:0:$(( ${CURSOR} + 1 ))}${CLIPBOARD}${BUFFER:$(( ${CURSOR} + 1 ))}"
	CURSOR=$(( $#LBUFFER + $#CLIPBOARD ))
}
zle -N zsh-system-clipboard-put-after

# Paste before cursor.
function zsh-system-clipboard-put-before() {
	local CLIPBOARD=$(_zsh_system_clipboard get)

	BUFFER="${BUFFER:0:$(( ${CURSOR} ))}${CLIPBOARD}${BUFFER:$(( ${CURSOR} ))}"
	CURSOR=$(( $#LBUFFER + $#CLIPBOARD - 1 ))
}
zle -N zsh-system-clipboard-put-before

# Cut selection.
function zsh-system-clipboard-cut() {
	zle vi-delete
	_zsh_system_clipboard set "$CUTBUFFER"
}
zle -N zsh-system-clipboard-cut

# Bind keys to widgets.
function () {
	local binded_keys i parts key cmd
	#
	binded_keys=(${(f)"$(bindkey -M vicmd)"})
	for (( i = 1; i < ${#binded_keys[@]}; ++i )); do
		parts=("${(z)binded_keys[$i]}")
		key="${parts[1]}"
		cmd="${parts[2]}"
		case $cmd in
			"vi-yank")
				eval bindkey -M vicmd $key zsh-system-clipboard-yank
				;;
			"vi-yank-whole-line")
				eval bindkey -M vicmd $key zsh-system-clipboard-yank-whole-line
				;;
			"vi-put-before")
				eval bindkey -M vicmd $key zsh-system-clipboard-put-before
				;;
			"vi-put-after")
				eval bindkey -M vicmd $key zsh-system-clipboard-put-after
				;;
			"vi-change-eol"|"vi-kill-eol"|"vi-change-whole-line"|"vi-change"|"vi-substitue"|"vi-delete"|"vi-delete-char"|"vi-backward-delete-char")
				eval bindkey -M vicmd $key zsh-system-clipboard-cut
				;;
		esac
	done
	binded_keys=(${(f)"$(bindkey -M visual)"})
	for (( i = 1; i < ${#binded_keys[@]}; ++i )); do
		parts=("${(z)binded_keys[$i]}")
		key="${parts[1]}"
		cmd="${parts[2]}"
		case $cmd in
			"put-replace-selection")
				eval bindkey -M visual $key zsh-system-clipboard-yank
				;;
			"vi-delete")
				eval bindkey -M visual $key zsh-system-clipboard-cut
				;;
		esac
	done
	# TODO: Run the same kind of commands for `bindkey -M emacs`
}
