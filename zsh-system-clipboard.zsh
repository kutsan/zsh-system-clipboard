#!/usr/bin/env zsh

##
# zsh-system-clipboard
#
# @author
#   Kutsan Kaplan <me@kutsan.dev>
#   Doron Behar <doron.behar@gmail.com>
# @license GPL-3.0
# @version v0.8.0
##

function _zsh_system_clipboard_command_exists() {
  type "$1" &> /dev/null;
}

function _zsh_system_clipboard_error() {
  echo -e "\n\n  \033[41;37m ERROR \033[0m \033[01mzsh-system-clipboard:\033[0m $@\n" >&2
}

function _zsh_system_clipboard_suggest_to_install() {
  _zsh_system_clipboard_error "Could not find any available clipboard manager. Make sure you have \033[01m${@}\033[0m installed."
  return 1
}

if [[ "$ZSH_SYSTEM_CLIPBOARD_METHOD" == "" ]]; then
  case "$OSTYPE" {
    darwin*)
      if _zsh_system_clipboard_command_exists pbcopy && _zsh_system_clipboard_command_exists pbpaste; then
        ZSH_SYSTEM_CLIPBOARD_METHOD="pb"
      else
        _zsh_system_clipboard_suggest_to_install 'pbcopy, pbpaste'
      fi
      ;;
    linux-android*)
      if _zsh_system_clipboard_command_exists termux-clipboard-set && _zsh_system_clipboard_command_exists termux-clipboard-get; then
        ZSH_SYSTEM_CLIPBOARD_METHOD="termux"
      else
        _zsh_system_clipboard_suggest_to_install 'Termux:API (from Play Store), termux-api (from apt package)'
      fi
      ;;
    linux*|freebsd*)
      if _zsh_system_clipboard_command_exists wl-copy; then
        ZSH_SYSTEM_CLIPBOARD_METHOD="wlc"
      elif _zsh_system_clipboard_command_exists xsel; then
        ZSH_SYSTEM_CLIPBOARD_METHOD="xsc"
      elif _zsh_system_clipboard_command_exists xclip; then
        ZSH_SYSTEM_CLIPBOARD_METHOD="xcc"
      elif _zsh_system_clipboard_command_exists clip.exe; then
        ZSH_SYSTEM_CLIPBOARD_METHOD="wsl"
      else
        _zsh_system_clipboard_suggest_to_install 'wl-clipboard / xsel / xclip'
      fi
      ;;
    *)
      _zsh_system_clipboard_error 'Unsupported system.'
      return 1
      ;;
  esac
fi
unfunction _zsh_system_clipboard_error
unfunction _zsh_system_clipboard_suggest_to_install
unfunction _zsh_system_clipboard_command_exists

function zsh-system-clipboard-set-tmux(){ tmux load-buffer -; }
function zsh-system-clipboard-get-tmux(){ tmux show-buffer; }
# wl{c,p} stands for 'wayland with {CLIPBOARD,PRIMARY} selection'
function zsh-system-clipboard-set-wlc(){ wl-copy; }
function zsh-system-clipboard-get-wlc(){ wl-paste -n; }
function zsh-system-clipboard-set-wlp(){ wl-copy -p; }
function zsh-system-clipboard-get-wlp(){ wl-paste -p -n; }
# wsl stands for 'Windows Subsystem for Linux'
# Based on: https://github.com/neovim/neovim/wiki/FAQ#how-to-use-the-windows-clipboard-from-wsl
function zsh-system-clipboard-set-wsl(){ clip.exe; }
function zsh-system-clipboard-get-wsl(){ powershell.exe -c '[Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))'; }
# xs{c,p} stands for 'xsel with {CLIPBOARD,PRIMARY} selection'
function zsh-system-clipboard-set-xsc(){ xsel -b -i; }
function zsh-system-clipboard-get-xsc(){ xsel -b -o; }
function zsh-system-clipboard-set-xsp(){ xsel -p -i; }
function zsh-system-clipboard-get-xsp(){ xsel -p -o; }
# xc{c,p} stands for 'xclip with {CLIPBOARD,PRIMARY} selection'
function zsh-system-clipboard-set-xcc(){ xclip -sel CLIPBOARD -in; }
function zsh-system-clipboard-get-xcc(){ xclip -sel CLIPBOARD -out; }
function zsh-system-clipboard-set-xcp(){ xclip -sel PRIMARY -in; }
function zsh-system-clipboard-get-xcp(){ xclip -sel PRIMARY -out; }
# pb stands for pbcopy and pbpaste
function zsh-system-clipboard-set-pb(){ pbcopy; }
function zsh-system-clipboard-get-pb(){ pbpaste; }
function zsh-system-clipboard-set-termux(){ termux-clipboard-set; }
function zsh-system-clipboard-get-termux(){ termux-clipboard-get; }

function zsh-system-clipboard-set(){ zsh-system-clipboard-set-${ZSH_SYSTEM_CLIPBOARD_METHOD}; }
function zsh-system-clipboard-get(){ zsh-system-clipboard-get-${ZSH_SYSTEM_CLIPBOARD_METHOD}; }

function zsh-system-clipboard-vicmd-vi-yank() {
  zle vi-yank
  if [[ "${KEYS}" == "y" && "${KEYMAP}" == 'viopp' ]]; then # A new line should be added to the end
    printf '%s\n' "$CUTBUFFER" | zsh-system-clipboard-set
  else
    printf '%s' "$CUTBUFFER" | zsh-system-clipboard-set
  fi
}
zle -N zsh-system-clipboard-vicmd-vi-yank

function zsh-system-clipboard-vicmd-vi-yank-eol() {
  zle vi-yank-eol
  printf '%s' "$CUTBUFFER" | zsh-system-clipboard-set
}
zle -N zsh-system-clipboard-vicmd-vi-yank-eol

function zsh-system-clipboard-vicmd-vi-yank-whole-line() {
  zle vi-yank-whole-line
  printf '%s\n' "$CUTBUFFER" | zsh-system-clipboard-set
}
zle -N zsh-system-clipboard-vicmd-vi-yank-whole-line

# Wrapper function for common calculations of both put-after and put-before
function zsh-system-clipboard-vicmd-vi-put() {
  local CLIPBOARD
  local mode="$1"
  CLIPBOARD="$(zsh-system-clipboard-get; printf '%s' x)"
  CLIPBOARD="${CLIPBOARD%x}"
  local RBUFFER_UNTIL_LINE_END="${RBUFFER%%$'\n'*}"
  # Checks if the last character is a new line
  if [[ "${CLIPBOARD[${#CLIPBOARD}]}" == $'\n' ]]; then
    # if so, we need to check if we have more lines below the cursor.
    # The following variable gets the contents of the whole RBUFFER up
    # until the next new-line. Therefor, this comparison tells us if we have
    # more new lines or not
    if [[ "${RBUFFER_UNTIL_LINE_END}" == "${RBUFFER}" && "$mode" == "after" ]]; then
      # we don't have any more newlines in RBUFFER.
      # Therefor, we add a new line at the beginning of our original
      # clipboard so it will append the whole BUFFER eventually
      CLIPBOARD=$'\n'"${CLIPBOARD%%$'\n'}"
    fi
    # If we are pasting a whole-line selection we need to put the cursor at
    # the correct position, according to our mode of input
    if [[ "$mode" == "after" ]]; then
      CURSOR="$(( ${CURSOR} + ${#RBUFFER_UNTIL_LINE_END} ))"
    else
      # We use the single % for the smallest match possible
      local LBUFFER_UNTIL_LINE_END="${LBUFFER%$'\n'*}"
      CURSOR="$(( ${#LBUFFER_UNTIL_LINE_END} + 1 ))"
    fi
  fi
  # If our selection is not whole lines, we need to check whether the line
  # our cursor is on an empty line or not and if it is, on the final
  # BUFFER modification, we'll always use the after mode. The length of
  # ${RBUFFER_UNTIL_LINE_END} tells as so - if it's 0
  if [[ "$mode" == "after" && ${#RBUFFER_UNTIL_LINE_END} != "0" ]]; then
    BUFFER="${BUFFER:0:$(( ${CURSOR} + 1 ))}${CLIPBOARD}${BUFFER:$(( ${CURSOR} + 1 ))}"
    CURSOR=$(( $#LBUFFER + $#CLIPBOARD ))
  else
    BUFFER="${BUFFER:0:$(( ${CURSOR} ))}${CLIPBOARD}${BUFFER:$(( ${CURSOR} ))}"
    CURSOR=$(( $#LBUFFER + $#CLIPBOARD - 1 ))
  fi
}

function zsh-system-clipboard-vicmd-vi-put-after() {
  zsh-system-clipboard-vicmd-vi-put after
}
zle -N zsh-system-clipboard-vicmd-vi-put-after

function zsh-system-clipboard-vicmd-vi-put-before() {
  zsh-system-clipboard-vicmd-vi-put before
}
zle -N zsh-system-clipboard-vicmd-vi-put-before

function zsh-system-clipboard-vicmd-vi-delete() {
  local region_was_active=${REGION_ACTIVE}
  zle vi-delete
  if [[ "${KEYS}" == "d" && "${region_was_active}" == 0 ]]; then # A new line should be added to the end
    printf '%s\n' "$CUTBUFFER" | zsh-system-clipboard-set
  else
    printf '%s' "$CUTBUFFER" | zsh-system-clipboard-set
  fi
}
zle -N zsh-system-clipboard-vicmd-vi-delete

function zsh-system-clipboard-vicmd-vi-delete-char() {
  zle vi-delete-char
  printf '%s' "$CUTBUFFER" | zsh-system-clipboard-set
}
zle -N zsh-system-clipboard-vicmd-vi-delete-char

function zsh-system-clipboard-vicmd-vi-change-eol() {
  zle vi-change-eol
  printf '%s' "$CUTBUFFER" | zsh-system-clipboard-set
}
zle -N zsh-system-clipboard-vicmd-vi-change-eol

function zsh-system-clipboard-vicmd-vi-kill-eol() {
  zle vi-kill-eol
  printf '%s' "$CUTBUFFER" | zsh-system-clipboard-set
}
zle -N zsh-system-clipboard-vicmd-vi-kill-eol

function zsh-system-clipboard-vicmd-vi-change-whole-line() {
  zle vi-change-whole-line
  printf '%s\n' "$CUTBUFFER" | zsh-system-clipboard-set
}
zle -N zsh-system-clipboard-vicmd-vi-change-whole-line

function zsh-system-clipboard-vicmd-vi-change() {
  zle vi-change
  printf '%s' "$CUTBUFFER" | zsh-system-clipboard-set
}
zle -N zsh-system-clipboard-vicmd-vi-change

function zsh-system-clipboard-vicmd-vi-substitue() {
  zle vi-substitue
  printf '%s' "$CUTBUFFER" | zsh-system-clipboard-set
}
zle -N zsh-system-clipboard-vicmd-vi-substitue

function zsh-system-clipboard-vicmd-vi-delete-char() {
  zle vi-delete-char
  printf '%s' "$CUTBUFFER" | zsh-system-clipboard-set
}
zle -N zsh-system-clipboard-vicmd-vi-delete-char

function zsh-system-clipboard-vicmd-vi-backward-delete-char() {
  zle vi-backward-delete-char
  printf '%s' "$CUTBUFFER" | zsh-system-clipboard-set
}
zle -N zsh-system-clipboard-vicmd-vi-backward-delete-char

function zsh-system-clipboard-visual-put-replace-selection(){
  local PUT
  local REPLACED

  # store the clipboard content on PUT
  PUT="$(zsh-system-clipboard-get; printf '%s' x)"
  PUT="${PUT%x}"

  # delete the current selection and store it on REPLACED
  zsh-system-clipboard-vicmd-vi-delete
  REPLACED="$(zsh-system-clipboard-get; printf '%s' x)"
  REPLACED="${REPLACED%x}"

  # reset the clipboard to PUT and put it before the current cursor positon
  printf '%s' "$PUT" | zsh-system-clipboard-set
  zsh-system-clipboard-vicmd-vi-put-before

  # restore the clipbard to REPLACED
  printf '%s' "$REPLACED" | zsh-system-clipboard-set
}
zle -N zsh-system-clipboard-visual-put-replace-selection

function zsh-system-clipboard-visual-vi-delete(){
  zsh-system-clipboard-vicmd-vi-delete
}
zle -N zsh-system-clipboard-visual-vi-delete

# Bind keys to widgets.
function () {
  if [[ -n "$ZSH_SYSTEM_CLIPBOARD_DISABLE_DEFAULT_MAPS" ]]; then
    return
  fi
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
