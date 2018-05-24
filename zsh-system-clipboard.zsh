##
# zsh-system-clipboard
#
# @author Kutsan Kaplan <me@kutsankaplan.com>
# @license GPLv3
# @version v0.4.0
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

			linux*)
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

function zsh-system-clipboard-key-y() {
	zle vi-yank
	_zsh_system_clipboard set "$CUTBUFFER"
}

function zsh-system-clipboard-key-Y() {
	zle vi-yank-whole-line
	_zsh_system_clipboard set "$CUTBUFFER"
}

function zsh-system-clipboard-key-yy() {
	zsh-system-clipboard-key-Y
}

function zsh-system-clipboard-key-p() {
	local CLIPBOARD=$(_zsh_system_clipboard get)

	BUFFER="${BUFFER:0:$(( ${CURSOR} + 1 ))}${CLIPBOARD}${BUFFER:$(( ${CURSOR} + 1 ))}"
	CURSOR=$(( $#LBUFFER + $#CLIPBOARD ))
}

function zsh-system-clipboard-key-P() {
	local CLIPBOARD=$(_zsh_system_clipboard get)

	BUFFER="${BUFFER:0:$(( ${CURSOR} ))}${CLIPBOARD}${BUFFER:$(( ${CURSOR} ))}"
	CURSOR=$(( $#LBUFFER + $#CLIPBOARD - 1 ))
}

function zsh-system-clipboard-key-x() {
	zle vi-delete
	_zsh_system_clipboard set "$CUTBUFFER"
}

# Load functions as widgets
foreach key (y yy Y p P x) {
	zle -N zsh-system-clipboard-key-$key
}

# Normal mode bindings
foreach key (yy Y p P) {
	bindkey -M vicmd $key zsh-system-clipboard-key-$key
}

# Visual mode bindings
foreach key (y x) {
	bindkey -M visual $key zsh-system-clipboard-key-$key
}
