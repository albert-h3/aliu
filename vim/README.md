# Cheatsheet

## Visual
- `*`/`#` in visual mode - search for the text under your cursor

## Normal Mode
- `gx` - go to URL under cursor
- `<leader>b` in normal - go to def
- `<C-B>` in normal - show this file in NERDTree
- `<leader>f` in normal - search for text
- `<leader>o` in normal - search for path
- `<C-G>` in normal - Open this in github
- `<leader>g` in normal - show commit for line

## NERDTree
- `R` - refresh
- `C` - Change the folder under the cursor to be the new root

## Ignoring Files
- For ripgrep: `.rgignore` file

## Environment Variables
My Vim config uses these environment variables at startup:

- `VIM_DEBUG` - Debug flag for vim

## Flags

#### Plugin Flags
Plugin flags are prefixed by `plug-`, in addition to `vim-`. So the `base` plugin
would be the flag `vim-plug-base`. When interacting with them via the `PlugFlag`
system, you refer to it just using the value `base`.

- `base`
  - UNIX file commands
  - Readline support
- `files` - enables NERDTree
- `solarized` - solarized color theme
- `fzf`
  - Fuzzy filename search
  - Fuzzy text search (requires ripgrep)
- `format` - Automatic formatting with :Autoformat
- `lsc` - Language server support for e.g. auto-importing functions
- `polyglot` - improved syntax highlighting
- `snippets` - Snippets

#### Other Flags
- `light-mode` - enables light mode
- `aliu` - Using `<C-T>` to put in a timestamped signature

## Default Flag Configuration
This command will add the default list plugins that I enable:
```
touch vim/flags/aliu vim/flags/plug-base \
    vim/flags/plug-files vim/flags/plug-fzf \
    vim/flags/plug-format vim/flags/plug-lsc \
    vim/flags/plug-polyglot
```

## Neovim vs Vim
Basic stuff is kept in the Vim folder for now; the neovim folder is where all
new configs should be kept.

## `compat`
Compatibility things should be implemented in the `compat` folder; for code specific
to this device, put it in a file called `this.lua` in the `compat` folder. Some examples:

```lua
-- Gitlab integration for vim fugitive `<C-G>`
local Util = require("util")
local Plug = Util.import("vim-plug")
Plug('shumphrey/fugitive-gitlab.vim')
Plug('ramilito/kubectl.nvim', {
  config = function()
    require("kubectl").setup()
  end
})

-- Font settings
vim.g.override_gui_font = "Source Code Pro"
vim.g.override_gui_font_size = 14

-- Copilot?
Plug('github/copilot.vim')
```

