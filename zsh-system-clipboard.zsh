##
# zsh-system-clipboard
#
# @author Kutsan Kaplan <me@kutsankaplan.com>
# @license GPLv3
# @version v0.1.0
##

function _zsh_system_clipboard_api() {
	local -A CLIPBOARD

	function determinate_clipboard_manager() {
		case "$OSTYPE" {
			darwin*)
				if (hash pbcopy 2>/dev/null && hash pbpaste 2>/dev/null) {
					typeset -g CLIPBOARD[set]='pbcopy'
					typeset -g CLIPBOARD[get]='pbpaste'
				}
				;;

			linux-android*)
				if (hash termux-clipboard-set 2>/dev/null && hash termux-clipboard-get 2>/dev/null) {
					typeset -g CLIPBOARD[set]='termux-clipboard-set'
					typeset -g CLIPBOARD[get]='termux-clipboard-get'
				}
				;;

			linux*)
				if (hash xsel 2>/dev/null) {
					typeset -g CLIPBOARD[set]='xsel --clipboard --input'
					typeset -g CLIPBOARD[get]='xsel --clipboard'
				}
				;;
		}
	}
	determinate_clipboard_manager

	function sub_set() {
		local ZSH_SYSTEM_CLIPBOARD_TMUX_SUPPORT='true'

		if [[ "$ZSH_SYSTEM_CLIPBOARD_TMUX_SUPPORT" != '' ]] {
			# Set also tmux clipboard buffer if tmux available.
			if (hash tmux &>/dev/null && [[ "$TMUX" != '' ]]) {
				tmux set-buffer -- "$@"
			}
		}

		printf "$@" | eval "${CLIPBOARD[set]}"
	}

	function sub_get() {
		set -x
		local CLIPBOARD_CONTENT=$(eval "${CLIPBOARD[get]}")
		printf "$CLIPBOARD_CONTENT"
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

function zsh-system-clipboard-key-y() {
	zle vi-yank
	_zsh_system_clipboard_api set "$CUTBUFFER"
}

function zsh-system-clipboard-key-Y() {
	zle vi-yank-whole-line
	_zsh_system_clipboard_api set "$CUTBUFFER"
}

function zsh-system-clipboard-key-p() {
	local CLIPBOARD=$(_zsh_system_clipboard_api get)
	tmux display-message $CLIPBOARD

	BUFFER="${BUFFER:0:$(( ${CURSOR} + 1 ))}${CLIPBOARD}${BUFFER:$(( ${CURSOR} + 1 ))}"
	CURSOR=$(( $#LBUFFER + $#CLIPBOARD ))
}

function zsh-system-clipboard-key-P() {
	local CLIPBOARD=$(_zsh_system_clipboard_api get)

	BUFFER="${BUFFER:0:$(( ${CURSOR} ))}${CLIPBOARD}${BUFFER:$(( ${CURSOR} ))}"
	CURSOR=$(( $#LBUFFER + $#CLIPBOARD - 1 ))
}

function zsh-system-clipboard-key-x() {
	zle vi-delete
	_zsh_system_clipboard_api set "$CUTBUFFER"
}

# Load functions as widgets
foreach widget (
	zsh-system-clipboard-key-y
	zsh-system-clipboard-key-Y
	zsh-system-clipboard-key-p
	zsh-system-clipboard-key-P
	zsh-system-clipboard-key-x
) {
	zle -N $widget
}

# Normal mode bindings
bindkey -M vicmd 'y' zsh-system-clipboard-key-y
bindkey -M vicmd 'Y' zsh-system-clipboard-key-Y
bindkey -M vicmd 'p' zsh-system-clipboard-key-p
bindkey -M vicmd 'P' zsh-system-clipboard-key-P

# Visual mode bindings
bindkey -M visual 'x' zsh-system-clipboard-key-x
