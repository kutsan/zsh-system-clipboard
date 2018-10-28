#!/usr/bin/env zsh

##
# zsh-system-clipboard
#
# @author
#	Kutsan Kaplan <me@kutsankaplan.com>
#	Doron Behar <doron.behar@gmail.com>
# @license GPL-3.0
# @version v0.7.0
##

function _zsh_system_clipboard_error() {
	echo -e "\n\n  \033[41;37m ERROR \033[0m \033[01mzsh-system-clipboard:\033[0m $@\n" >&2
}

function _zsh_system_clipboard_suggest_to_install() {
	_zsh_system_clipboard_error "Could not find any available clipboard manager. Make sure you have \033[01m${@}\033[0m installed."
}

typeset -A ZSH_SYSTEM_CLIPBOARD
case "$OSTYPE" {
	darwin*)
		if ((hash pbcopy && hash pbpaste) 2>/dev/null) {
			typeset -g ZSH_SYSTEM_CLIPBOARD[set]='pbcopy'
			typeset -g ZSH_SYSTEM_CLIPBOARD[get]='pbpaste'
		} else {
			_zsh_system_clipboard_suggest_to_install 'pbcopy, pbpaste'
		}
		;;
	linux-android*)
		if ((hash termux-clipboard-set && hash termux-clipboard-get) 2>/dev/null) {
			typeset -g ZSH_SYSTEM_CLIPBOARD[set]='termux-clipboard-set'
			typeset -g ZSH_SYSTEM_CLIPBOARD[get]='termux-clipboard-get'
		} else {
			_zsh_system_clipboard_suggest_to_install 'Termux:API (from Play Store), termux-api (from apt package)'
		}
		;;
	linux*|freebsd*)
		if (hash xclip 2>/dev/null) {
			local clipboard_selection
			case $ZSH_SYSTEM_CLIPBOARD_SELECTION {
				PRIMARY)
					clipboard_selection='PRIMARY'
					;;
				CLIPBOARD)
					clipboard_selection='CLIPBOARD'
					;;
				*)
					if [[ $ZSH_SYSTEM_CLIPBOARD_SELECTION != '' ]] {
						_zsh_system_clipboard_error "\033[01m$ZSH_SYSTEM_CLIPBOARD_SELECTION\033[0m is not a valid value for \$ZSH_SYSTEM_CLIPBOARD_SELECTION. Please assign either 'PRIMARY' or 'CLIPBOARD'."
					} else {
						clipboard_selection='CLIPBOARD'
					}
					;;
			}
			if [[ ! -z $DISPLAY ]]; then
				typeset -g ZSH_SYSTEM_CLIPBOARD[set]="xclip -sel $clipboard_selection -in"
				typeset -g ZSH_SYSTEM_CLIPBOARD[get]="xclip -sel $clipboard_selection -out"
			fi
		} elif (hash xsel 2>/dev/null) {
			local clipboard_selection
			case $ZSH_SYSTEM_CLIPBOARD_SELECTION {
				PRIMARY)
					clipboard_selection='-p'
					;;
				CLIPBOARD)
					clipboard_selection='-b'
					;;
				*)
					if [[ $ZSH_SYSTEM_CLIPBOARD_SELECTION != '' ]] {
						_zsh_system_clipboard_error "\033[01m$ZSH_SYSTEM_CLIPBOARD_SELECTION\033[0m is not a valid value for \$ZSH_SYSTEM_CLIPBOARD_SELECTION. Please assign either 'PRIMARY' or 'CLIPBOARD'."
					} else {
						clipboard_selection='-b'
					}
					;;
			}
			if [[ ! -z $DISPLAY ]]; then
				typeset -g ZSH_SYSTEM_CLIPBOARD[set]="xsel $clipboard_selection -i"
				typeset -g ZSH_SYSTEM_CLIPBOARD[get]="xsel $clipboard_selection -o"
			fi
		} else {
			_zsh_system_clipboard_suggest_to_install 'xclip or xsel'
		}
		;;
	*)
		_zsh_system_clipboard_error 'Unsupported system.'
		;;
}
unfunction _zsh_system_clipboard_error
unfunction _zsh_system_clipboard_suggest_to_install

function _zsh_system_clipboard_set() {
	if [[ "$ZSH_SYSTEM_CLIPBOARD_TMUX_SUPPORT" != '' ]] {
		# Set also tmux clipboard buffer if tmux available.
		if (hash tmux &>/dev/null && [[ "$TMUX" != '' ]]) {
			tmux set-buffer -- "$*"
		}
	}
	eval "${ZSH_SYSTEM_CLIPBOARD[set]}" <<< "$1"
	return true
}
function _zsh_system_clipboard_get() {
	eval "${ZSH_SYSTEM_CLIPBOARD[get]}"
	return true
}

function zsh-system-clipboard-vicmd-vi-yank() {
	zle vi-yank
	_zsh_system_clipboard_set "$CUTBUFFER"
}
zle -N zsh-system-clipboard-vicmd-vi-yank

function zsh-system-clipboard-vicmd-vi-yank-whole-line() {
	zle vi-yank-whole-line
	_zsh_system_clipboard_set "$CUTBUFFER"
}
zle -N zsh-system-clipboard-vicmd-vi-yank-whole-line

function zsh-system-clipboard-vicmd-vi-put-after() {
	local CLIPBOARD="$(_zsh_system_clipboard_get; printf '%s' x)"
	CLIPBOARD="${CLIPBOARD%x}"
	if [[ "${CLIPBOARD[${#CLIPBOARD}]}" == $'\n' ]]; then
		local RBUFFER_UNTIL_LINE_END="${RBUFFER%%$'\n'*}"
		if [[ "${RBUFFER_UNTIL_LINE_END}" == "${RBUFFER}" ]]; then
			# we don't have any more newlines so in RBUFFER
			CLIPBOARD=$'\n'"${CLIPBOARD%%$'\n'*}"
			CURSOR="${#BUFFER}"
		else
			CLIPBOARD="${CLIPBOARD%%$'\n'*}"$'\n'
			local RBUFFER_LINE_END_INDEX="${#RBUFFER_UNTIL_LINE_END}"
			CURSOR="$(( ${CURSOR} + ${RBUFFER_LINE_END_INDEX} ))"
		fi
	fi

	BUFFER="${BUFFER:0:$(( ${CURSOR} + 1 ))}${CLIPBOARD}${BUFFER:$(( ${CURSOR} + 1 ))}"
	CURSOR=$(( $#LBUFFER + $#CLIPBOARD ))
}
zle -N zsh-system-clipboard-vicmd-vi-put-after

function zsh-system-clipboard-vicmd-vi-put-before() {
	local CLIPBOARD="$(_zsh_system_clipboard_get; printf '%s' x)"
	CLIPBOARD="${CLIPBOARD%x}"
	if [[ "${CLIPBOARD[${#CLIPBOARD}]}" == $'\n' ]]; then
		local RBUFFER_UNTIL_LINE_END="${RBUFFER%%$'\n'*}"
		if [[ "${RBUFFER_UNTIL_LINE_END}" == "${RBUFFER}" ]]; then
			# we don't have any more newlines so in RBUFFER
			CLIPBOARD=$'\n'"${CLIPBOARD%%$'\n'*}"
			CURSOR="${#BUFFER}"
		else
			CLIPBOARD="${CLIPBOARD%%$'\n'*}"$'\n'
			local RBUFFER_LINE_END_INDEX="${#RBUFFER_UNTIL_LINE_END}"
			CURSOR="$(( ${CURSOR} + ${RBUFFER_LINE_END_INDEX} ))"
		fi
	fi

	BUFFER="${BUFFER:0:$(( ${CURSOR} ))}${CLIPBOARD}${BUFFER:$(( ${CURSOR} ))}"
	CURSOR=$(( $#LBUFFER + $#CLIPBOARD - 1 ))
}
zle -N zsh-system-clipboard-vicmd-vi-put-before

function zsh-system-clipboard-vicmd-vi-delete() {
	zle vi-delete
	_zsh_system_clipboard_set "$CUTBUFFER"
}
zle -N zsh-system-clipboard-vicmd-vi-delete

function zsh-system-clipboard-vicmd-vi-delete-char() {
	zle vi-delete-char
	_zsh_system_clipboard_set "$CUTBUFFER"
}
zle -N zsh-system-clipboard-vicmd-vi-delete-char

function zsh-system-clipboard-vicmd-vi-change-eol() {
	zle vi-change-eol
	_zsh_system_clipboard_set "$CUTBUFFER"
}
zle -N zsh-system-clipboard-vicmd-vi-change-eol

function zsh-system-clipboard-vicmd-vi-kill-eol() {
	zle vi-kill-eol
	_zsh_system_clipboard_set "$CUTBUFFER"
}
zle -N zsh-system-clipboard-vicmd-vi-kill-eol

function zsh-system-clipboard-vicmd-vi-change-whole-line() {
	zle vi-change-whole-line
	_zsh_system_clipboard_set "$CUTBUFFER"
}
zle -N zsh-system-clipboard-vicmd-vi-change-whole-line

function zsh-system-clipboard-vicmd-vi-change() {
	zle vi-change
	_zsh_system_clipboard_set "$CUTBUFFER"
}
zle -N zsh-system-clipboard-vicmd-vi-change

function zsh-system-clipboard-vicmd-vi-substitue() {
	zle vi-substitue
	_zsh_system_clipboard_set "$CUTBUFFER"
}
zle -N zsh-system-clipboard-vicmd-vi-substitue

function zsh-system-clipboard-vicmd-vi-delete-char() {
	zle vi-delete-char
	_zsh_system_clipboard_set "$CUTBUFFER"
}
zle -N zsh-system-clipboard-vicmd-vi-delete-char

function zsh-system-clipboard-vicmd-vi-backward-delete-char() {
	zle vi-backward-delete-char
	_zsh_system_clipboard_set "$CUTBUFFER"
}
zle -N zsh-system-clipboard-vicmd-vi-backward-delete-char

# Bind keys to widgets.
function () {
	local binded_keys i parts key cmd keymap
	for keymap in vicmd visual emacs; do
		binded_keys=(${(f)"$(bindkey -M $keymap)"})
		for (( i = 1; i < ${#binded_keys[@]}; ++i )); do
			parts=("${(z)binded_keys[$i]}")
			key="${parts[1]}"
			cmd="${parts[2]}"
			if (( $+functions[zsh-system-clipboard-$keymap-$cmd] )); then
				eval bindkey -M $keymap $key zsh-system-clipboard-$keymap-$cmd
			fi
		done
	done
}
