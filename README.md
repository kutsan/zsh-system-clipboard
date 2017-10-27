# zsh-system-clipboard

Zsh plugin that adds key bindings support for ZLE (Zsh Line Editor) clipboard operations for vi emulation keymaps. It works under Linux, macOS and Android (via Termux).

![Demonstration](https://i.imgur.com/LyL0GfQ.gif)

By default, ZLE has its own clipboard buffer. So, using keys like <kbd>y</kbd> when ZLE's normal mode for yanking operations will not send that yanked text to system clipboard. It will live inside ZLE and using <kbd>C-v</kbd> won't paste that text in another program. This plugin synchronize your system clipboard with ZLE buffers while it's not overriding anything. You can still use ZLE's <kbd>"</kbd> register if you want to.

It also synchronize [tmux](https://github.com/tmux/tmux) clipboard buffers if tmux available and the `ZSH_SYSTEM_CLIPBOARD_TMUX_SUPPORT` variable is set to `'true'`. See "Options" section for more details.

## Installation

Clone the project and source the `zsh-system-clipboard.zsh` file somewhere in your `.zshrc`. It is important, **you need to have** `bindkey -v` (vi emulation mode) before sourcing it, in order to use this plugin. Plugin itself is not resetting keymaps to make it work. If you already have, you don't need to add it.

```sh
bindkey -v
source /path/to/project/zsh-system-clipboard.zsh
```

> Feel free to create a issue if you want to install it via your favorite plugin manager.

## Usage

Basically, this plugin overrides some existing key bindings; those are the same as in Vim (only following keys are implemented). It will be intuitive to use if you already using Vim. Otherwise, check out below.

#### Normal mode

- <kbd>Y</kbd> Copy whole line to clipboard.
- <kbd>p</kbd> Paste after the cursor.
- <kbd>P</kbd> Paste before the cursor.

#### Visual mode

You need to select some text first **when ZLE's visual mode** to use those keys.

- <kbd>y</kbd> Copy selected text to clipboard.
- <kbd>x</kbd> Cut and send to clipboard.

> More keys will be added. Feel free to file a issue.

## Options

- `ZSH_SYSTEM_CLIPBOARD_TMUX_SUPPORT`: Set it to 'true' to enable tmux support. That way, if tmux available, every new clipboard content will be also sent to tmux clipboard buffers. Run `tmux choose-buffer` to view them.

## License

GPLv3
