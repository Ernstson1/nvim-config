# nvim-config

My Neovim setup, built on [LazyVim](https://github.com/LazyVim/LazyVim). Tuned for C/C++ (CMake), Python, C# and Markdown.

## Install

### Linux (apt, dnf or pacman)

```bash
git clone https://github.com/Ernstson1/nvim-config.git
cd nvim-config
./install.sh
```

The script installs:

- Neovim, lazygit and .NET
- the runtimes that language servers need: Node, Python, a JDK and a C compiler
- JetBrainsMono Nerd Font, on desktop systems only

It then links the repo to `~/.config/nvim`, moving any existing config to `~/.config/nvim.bak.<date>`. Finally it installs all plugins, language servers and treesitter parsers, so Neovim is ready on the first launch. It needs `sudo` for the system packages.

Afterwards, open a new shell. On a desktop, set your terminal font to *JetBrainsMono Nerd Font Mono*.

### macOS

```bash
brew install neovim lazygit ripgrep node python dotnet
brew install --cask font-jetbrains-mono-nerd-font
git clone https://github.com/Ernstson1/nvim-config.git ~/.config/nvim
```

## What's in it

- Theme: gruvbox-material (soft).
- LazyVim extras are listed in `lazyvim.json`.
- Plugin versions are pinned in `lazy-lock.json`.
- Custom settings live in `lua/plugins/`, with one file per topic.
- C#: OmniSharp, plus [easy-dotnet.nvim](https://github.com/GustavEikaas/easy-dotnet.nvim) for build, run and tests. Test keymaps are under `<leader>T`.
- Markdown: Prettier wraps lines at 80 columns when you save.
- The arrow keys are disabled in normal and visual mode. Use `hjkl`.

## License

[Apache License 2.0](LICENSE). This repo is derived from the [LazyVim starter](https://github.com/LazyVim/starter), which uses the same license. Files changed from the starter are marked with a notice at the top.
