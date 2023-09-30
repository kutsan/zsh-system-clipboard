<img width="100" src="https://github.com/kutsan/zsh-system-clipboard/raw/master/.github/assets/logo.png" alt="Logo" />

# zsh-system-clipboard

Zsh plugin that adds key bindings support for ZLE (Zsh Line Editor) clipboard operations for vi emulation keymaps. It works under Linux, macOS and Android (via Termux).

![demonstration-gif](https://i.imgur.com/LyL0GfQ.gif)

By default, ZLE has its own clipboard buffer. So, using keys like <kbd>y</kbd> inside ZLE's normal mode for yanking operations will not send that yanked text to system clipboard. It will live inside ZLE and using <kbd>C-v</kbd> won't paste that text in another program. This plugin synchronizes your system clipboard with ZLE buffers while it's not overriding anything. You can still use ZLE's <kbd>"</kbd> register if you want to.

It also synchronizes [tmux](https://github.com/tmux/tmux) clipboard buffers if tmux available and the `ZSH_SYSTEM_CLIPBOARD_TMUX_SUPPORT` variable is set to `'true'`. See _Options_ section for more details.

## Installation

#### Using Plugin Managers

Use your favorite plugin manager, e.g. [zplug](https://github.com/zplug/zplug):

```sh
zplug "kutsan/zsh-system-clipboard"
```

#### Manually

Clone this repository somewhere,

```
git clone https://github.com/kutsan/zsh-system-clipboard ${ZSH_CUSTOM:-~/.zsh}/plugins/zsh-system-clipboard

```

Source the [`zsh-system-clipboard.zsh`](https://github.com/kutsan/zsh-system-clipboard/blob/master/zsh-system-clipboard.zsh) file in your `~/.zshrc`.

```sh
source "${ZSH_CUSTOM:-~/.zsh}/plugins/zsh-system-clipboard/zsh-system-clipboard.zsh"
```

The script `zsh-system-clipboard.zsh` parses the output of `bindkey -M vicmd`, `bindkey -M emacs`, `bindkey -M visual` in order to rebind your keys (along with the default ones) the [`ZLE widgets`](http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Zle-Widgets) functions that copy from and paste to the system clipboard. This means that you should put all of your bindings before sourcing `zsh-system-clipboard.zsh` in your `~/.zshrc`.

**Note: widget functions that replace builtin functions for the `emacs` keymap are not yet written (see #12).**

## Options

### `ZSH_SYSTEM_CLIPBOARD_METHOD`

Sets the clipboard method to either of these options:

| method value | meaning |
| ------------ | ------- |
| `tmux`       | Use Tmux's buffer as a clipboard - useful on systems without X / wayland, requires `set-option -g set-clipboard on` in `~/.tmux.conf` |
| `xsc`        | Use [`xsel`](https://github.com/kfish/xsel) with 'CLIPBOARD' selection. |
| `xsp`        | Use [`xsel`](https://github.com/kfish/xsel) with 'PRIMARY' selection. |
| `xcc`        | Use [`xclip`](https://github.com/astrand/xclip) with 'CLIPBOARD' selection. |
| `xcp`        | Use [`xclip`](https://github.com/astrand/xclip) with 'PRIMARY' selection. |
| `wlc`        | Use [`wl-clipboard`](https://github.com/bugaevc/wl-clipboard) with 'CLIPBOARD' selection. |
| `wlp`        | Use [`wl-clipboard`](https://github.com/bugaevc/wl-clipboard) with 'PRIMARY' selection. |
| `pb`         | Use `pbcopy` and `pbpaste` on Darwin - method used by default on OSx. |
| `termux`     | Use [Termux:API](https://wiki.termux.com/wiki/Termux:API) - method used by default on Android's termux |

### `ZSH_SYSTEM_CLIPBOARD_DISABLE_DEFAULT_MAPS`

If set to a non-empty value, it disables the default bindings zsh-system-clipboard uses. Why would you want to do that?

zsh-system-clipboard modifies your key bindings by reading them in their current state and binds them to their corresponding widgets we implemented which change the system clipboard along the way. This variable enables you to bind the default bindings your way. This is useful if you wish e.g to use the same default bindings but with a certain prefix.

This is the function that's inside `zsh-system-clipboard.zsh` which actually binds the default keys:

```zsh
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
```

You can change the line `eval bindkey -M $keymap $key zsh-system-clipboard-$keymap-$cmd` this way:

```zsh
        eval bindkey -M $keymap \"\ \"$key zsh-system-clipboard-$keymap-$cmd
```

And to make this change useful, unbind the single `" "` with:

```zsh
bindkey -ar " "
```

This setup will force you to use <kbd>space</kbd> to actually use the system clipboard - whether it's paste or copy.

## API

The plugin itself provides a separate cross-platform clipboard API for internal widgets. You can use this API as a standalone function.

To set system clipboard buffer:

```sh
zsh-system-clipboard-set "example text"
```

To get system clipboard buffer to `stdout`:

```sh
zsh-system-clipboard-get
```

It will show pretty-printed errors via `stderr` or `stdout` if something went wrong.

## Additional mappings

`zsh-system-clipboard` emulates all of zsh's standard mappings but with system clipboard support. Some default `zle` commands are not mapped by default both by us and both by ZSH. However we have the binding `zsh-system-clipboard-vicmd-vi-yank-eol` which emulates `vi-yank-eol` which copies text from cursor to the end of the line but we don't map it to anything, no matter what is `$ZSH_SYSTEM_CLIPBOARD_DISABLE_DEFAULT_MAPS`. To use it, add to your `~/.zshrc`:

```zsh
# Bind Y to yank until end of line
bindkey -M vicmd Y zsh-system-clipboard-vicmd-vi-yank-eol
```

## Thanks

Special thanks to _Doron Behar ([@doronbehar](https://github.com/doronbehar))_ for their interests, suggestions, time and pull requests.

## Similar Projects

- [zsh-vi-more/evil-registers](https://github.com/zsh-vi-more/evil-registers)

## License

GPL-3.0
