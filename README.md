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

and source the `zsh-system-clipboard.zsh` file in your `.zshrc`.

```sh
source "$HOME/.zsh/plugins/zsh-system-clipboard/zsh-system-clipboard.zsh"
```

## Usage

Keys are the same as in Vim (only following keys are implemented). It will be intuitive to use if you already using Vim.

#### Normal mode

- <kbd>Y</kbd> Copy whole line to clipboard.
- <kbd>yy</kbd> Same as <kbd>Y</kbd>. _(Tweak `KEYTIMEOUT`, if doesn't work.)_
- <kbd>p</kbd> Paste after the cursor.
- <kbd>P</kbd> Paste before the cursor.

#### Visual mode

Select some text first with ZLE's visual mode to use those keys.

- <kbd>y</kbd> Copy selected text to clipboard.
- <kbd>x</kbd> Cut and send to clipboard.

> You may want to set the color to see visual selection better with `typeset -g zle_highlight=(region:bg=yellow)`.

## Options

- `ZSH_SYSTEM_CLIPBOARD_TMUX_SUPPORT`: Set it to `'true'` to enable tmux support. That way, if tmux available, every new clipboard content will be also sent to tmux clipboard buffers. Run `tmux choose-buffer` to view them.
- `ZSH_SYSTEM_CLIPBOARD_XCLIP_SELECTION`: Specify which X selection to use for `xclip` utility. Either `'PRIMARY'` or `'CLIPBOARD'`. Defaults to `'CLIPBOARD'`.

For example:

```sh
typeset -g ZSH_SYSTEM_CLIPBOARD_TMUX_SUPPORT='true'
typeset -g ZSH_SYSTEM_CLIPBOARD_XCLIP_SELECTION='PRIMARY'
```

## API

The plugin itself provides a separate cross-platform clipboard API for internal widgets. You can use this API as a standalone function.

To set system clipboard buffer:

```sh
_zsh_system_clipboard set "example text"
```

To get system clipboard buffer to `stdout`:

```sh
_zsh_system_clipboard get
```

It will show pretty-printed errors via `stderr` or `stdout` if something went wrong.

## Thanks

Special thanks to _Doron Behar ([@doronbehar](https://github.com/doronbehar))_ for their interests, suggestions, time and pull requests.

## License

GPL-3.0
