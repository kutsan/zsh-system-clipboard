# zsh-system-clipboard

Zsh plugin that adds key bindings support for ZLE (Zsh Line Editor) clipboard operations for vi emulation keymaps.

> The plugin in its early stage. It needs many improvements and for now it's not intended to use. Come back later or use this experimental version and provide feedbacks. Also, it's only tested on the latest version of Zsh.

By default, ZLE has its own clipboard buffer. So, using keys like <kbd>y</kbd> when ZLE's normal mode for yanking operations will not send that yanked text to system clipboard. It will live inside ZLE and using <kbd>C-v</kbd> won't paste that text in another program. This plugin synchronize your system clipboard with ZLE buffers while it's not overriding anything. You can still use ZLE's <kbd>"</kbd> buffers if you want to.

## Installation

Clone the project and source the `zsh-system-clipboard.zsh` file somewhere in your `.zshrc`.

```
source /path/to/project/zsh-system-clipboard.zsh
```

## Usage

> TODO but basically using key like `y, Y, p, P` will do the trick. More keys will be added.

## License

GPLv3
