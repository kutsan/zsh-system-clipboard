##
# zsh-system-clipboard
#
# @author Kutsan Kaplan <me@kutsankaplan.com>
# @license GPLv3
# @version v0.3.0
##

function _zsh_system_clipboard_api() {
	function _console.error() {
		echo -e "\n\n  \033[41;37m ERROR \033[0m \033[01mzsh-system-clipboard:\033[0m $@\n" >&2
		return true
	}

	function _console.error_and_suggest_to_install() {
		_console.error "Could not find any available clipboard manager. Make sure you have \033[01m${@}\033[0m installed."
		return true
	}

	local -A CLIPBOARD

	function determinate_clipboard_manager() {
		case "$OSTYPE" {
			darwin*)
				if ((hash pbcopy && hash pbpaste) 2>/dev/null) {
					typeset -g CLIPBOARD[set]='pbcopy'
					typeset -g CLIPBOARD[get]='pbpaste'
				} else {
					_console.error_and_suggest_to_install 'pbcopy, pbpaste'
				}
				;;

			linux-android*)
				if ((hash termux-clipboard-set && hash termux-clipboard-get) 2>/dev/null) {
					typeset -g CLIPBOARD[set]='termux-clipboard-set'
					typeset -g CLIPBOARD[get]='termux-clipboard-get'
				} else {
					_console.error_and_suggest_to_install 'Termux:API (from Play Store), termux-api (from apt package)'
				}
				;;

			linux*)
				if (hash xclip 2>/dev/null) {
					typeset -g CLIPBOARD[set]='xclip -in'
					typeset -g CLIPBOARD[get]='xclip -out'
				} else {
					_console.error_and_suggest_to_install 'xclip'
				}
				;;

			*)
				_console.error 'Unsupported system.'
				;;
		}
	}
	determinate_clipboard_manager

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
			sub_${subcommand} "$*" || return false

			return true
			;;

		get)
			shift
			sub_${subcommand} || return false

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
foreach key (y Y p P x) {
	zle -N zsh-system-clipboard-key-$key
}

# Normal mode bindings
foreach key (Y p P) {
	bindkey -M vicmd $key zsh-system-clipboard-key-$key
}

# Visual mode bindings
foreach key (y x) {
	bindkey -M visual $key zsh-system-clipboard-key-$key
}
