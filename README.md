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
git clone https://github.com/kutsan/zsh-system-clipboard ~/.zsh/plugins/zsh-system-clipboard
```

Source the [`zsh-system-clipboard.zsh`](https://github.com/kutsan/zsh-system-clipboard/blob/master/zsh-system-clipboard.zsh) file in your `~/.zshrc`.

```sh
source "$HOME/.zsh/plugins/zsh-system-clipboard/zsh-system-clipboard.zsh"
```

The script `zsh-system-clipboard.zsh` parses the output of `bindkey -M vicmd`, `bindkey -M emacs`, `bindkey -M visual` in order to rebind your keys (along with the default ones) the [`ZLE widgets`](http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Zle-Widgets) functions that copy from and paste to the system clipboard. This means that you should put all of your bindings before sourcing `zsh-system-clipboard.zsh` in your `~/.zshrc`.

**Note: widget functions that replace builtin functions for the `emacs` keymap are not yet written (see #12).**

## Options

- `ZSH_SYSTEM_CLIPBOARD_TMUX_SUPPORT`: Set it to `'true'` to enable tmux support. That way, if tmux available, every new clipboard content will be also sent to tmux clipboard buffers. Run `tmux choose-buffer` to view them.
- `ZSH_SYSTEM_CLIPBOARD_SELECTION`: Specify which X selection to use for `xclip` or `xsel` or `wl-copy` utilities. Either `'PRIMARY'` or `'CLIPBOARD'`. Defaults to `'CLIPBOARD'`.
- `ZSH_SYSTEM_CLIPBOARD_USE_WL_CLIPBOARD`: zsh-system-clipboard doesn't use `wl-copy` or `wl-paste` even if they are installed, if you have `$DISPLAY` set. However, it may be that you _use_ Wayland (and hence you can use these utilities), but `$DISPLAY` is set in your environment, perhaps because you use an X based terminal emulator on Wayland. In that case, if you don't have `xsel` or `xclip` installed and you wish to use `wl-copy` never the less, you should set this environment variable to `true`. To summarise, set this variable if:
	 - You use Wayland.
	 - You have `wl-clipboard` installed.
   - You don't have `xsel` or `xclip` utilities installed.
	 - You have `$DISPLAY` set in your environment (probably due to the X emulator).
	 - You would like to use `wl-copy` and `wl-paste` utilities because you use Wayland.

For example:

```sh
typeset -g ZSH_SYSTEM_CLIPBOARD_TMUX_SUPPORT='true'
typeset -g ZSH_SYSTEM_CLIPBOARD_SELECTION='PRIMARY'
```

## Configuration

If you wish, you can disable the default bindings zsh-system-clipboard uses by setting the following in your environment:

```zsh
export ZSH_SYSTEM_CLIPBOARD_DISABLE_DEFAULT_MAPS=1
```

Why would I want to do that?

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
_zsh_system_clipboard_set "example text"
```

To get system clipboard buffer to `stdout`:

```sh
_zsh_system_clipboard_get
```

It will show pretty-printed errors via `stderr` or `stdout` if something went wrong.

## Thanks

Special thanks to _Doron Behar ([@doronbehar](https://github.com/doronbehar))_ for their interests, suggestions, time and pull requests.

## Similar Projects

- [zsh-vi-more/evil-registers](https://github.com/zsh-vi-more/evil-registers)

## License

GPL-3.0
