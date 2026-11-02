# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

LazyVim-based Neovim config (from the LazyVim starter template).

## My setup
- macOS, Ghostty terminal, Swedish keyboard layout
- Ghostty uses `macos-option-as-alt = left`, so Alt bindings use left Option
- Languages I use: C/C++ (CMake), Python, C#, Markdown

## Rules
- One file per topic in `lua/plugins/` (e.g. `cmake.lua`, `csharp.lua`)
- Override LazyVim through `opts`, don't copy full plugin specs
- Prefer enabling LazyVim extras over adding plugins manually
- Don't edit `lazy-lock.json` by hand
- Keep the config portable across macOS and Linux: no hardcoded paths (e.g. Homebrew); rely on PATH or Mason
- A new external dependency (runtime, CLI tool) must also be added to `install.sh`

## Commands
- Format Lua: `stylua .` (config in `stylua.toml`: 2 spaces, 120 cols)
- Check the config loads without errors: `nvim --headless "+Lazy! sync" +qa`
- Inside Neovim: `:Lazy` (plugins), `:LazyExtras` (toggle extras), `:Mason` (tools), `:checkhealth`, `:ConformInfo` (formatters for current buffer)

## Linux setup
`install.sh` sets up a fresh Linux machine (apt/dnf/pacman): system packages (node, python, JDK, C compiler, ripgrep), latest Neovim and lazygit from GitHub releases, .NET LTS in `~/.dotnet`, JetBrainsMono Nerd Font (desktops only), a PATH block in `~/.bashrc`/`~/.zshrc`, symlinks the repo to `~/.config/nvim`, then `Lazy! restore`. Mason tools and treesitter parsers install on first launch. Test changes to it in a container: `docker run --rm -it -v "$PWD":/src:ro ubuntu:24.04` (copy `/src` elsewhere first, since the script symlinks the repo).

## How it fits together
- `init.lua` → `lua/config/lazy.lua` bootstraps lazy.nvim, imports `lazyvim.plugins`, then every file in `lua/plugins/`. Each file returns a spec (or list of specs) that is merged into LazyVim's spec for the same plugin.
- Enabled extras live in `lazyvim.json` (managed by `:LazyExtras`; editing the `extras` list by hand also works).
- `lua/config/options.lua` loads before plugins; `keymaps.lua` and `autocmds.lua` load on `VeryLazy`, after LazyVim's defaults.
- `opts` as a table is deep-merged; lists are replaced unless the spec declares `opts_extend` (LazyVim does for treesitter's and mason's `ensure_installed`). Otherwise use `opts = function(_, opts) vim.list_extend(...) end`, which must mutate or return `opts`.
- Custom plugins are not lazy-loaded by default (`defaults.lazy = false`).
- Neo-tree comes from the `neo-tree` extra, which also owns `<leader>e`/`<leader>E`/`<leader>fe`/`<leader>fE`.
- C# LSP is omnisharp from the `dotnet` extra. `easy-dotnet.nvim` (in `csharp.lua`) has its own Roslyn LSP disabled to avoid running two servers; its test-file keymaps are moved under `<leader>T`.
- Markdown formatting is prettier (`formatting.prettier` extra) with `--prose-wrap always` set in `lua/plugins/markdown.lua`.

## Making changes
Look up what LazyVim already does before writing anything. Installed source (matches the version actually running):
- Core plugin specs and their default `opts`: `~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/`
- Extras: `~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/extras/` (enabled ones are listed in `lazyvim.json`)
- Default options/keymaps/autocmds: `~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/config/`
- Docs: https://www.lazyvim.org (extras and per-plugin keymaps)

Decision order:
1. Is there an extra for it? Enable it in `lazyvim.json`.
2. Is the plugin already in LazyVim (core or enabled extra)? Override its `opts` in the topic file, referencing it by the same name LazyVim uses.
3. Otherwise add a new spec in a topic file. Use `opts` (lazy.nvim calls `setup(opts)`) rather than `config` unless the plugin has no `setup`.

Where things go:
- New language tooling (LSP, formatter, linter, parser): `lua/plugins/<language>.lua`. LSP servers via `nvim-lspconfig` `opts.servers`, formatters via `conform.nvim` `opts.formatters_by_ft`/`opts.formatters`, tools via `mason.nvim` `opts.ensure_installed`.
- Colorscheme: `lua/plugins/colorscheme.lua`, selected via `LazyVim/LazyVim` `opts.colorscheme`.
- Vim options: `lua/config/options.lua`. Global keymaps: `lua/config/keymaps.lua`. Plugin-specific keymaps: the plugin spec's `keys`.

Before adding a keymap, grep LazyVim's source for the key so it doesn't shadow a default or create a prefix clash (e.g. `<leader>e` and `<leader>ef` makes `<leader>e` wait for `timeoutlen`).

Verifying:
- Load check: the headless command under Commands; any error prints to stdout.
- Headless doesn't fire `VeryLazy`, so `keymaps.lua` isn't loaded there. To check a mapping: `nvim --headless "+lua vim.defer_fn(function() dofile('lua/config/keymaps.lua'); io.stdout:write(vim.fn.maparg(' fo','n')..'\n'); vim.cmd('qa!') end, 2000)"`
- Formatter check: open a sample file headless, run `require('conform').format({ bufnr = 0, timeout_ms = 10000 })`, write and inspect.
