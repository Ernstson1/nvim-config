#!/usr/bin/env bash
# Sets up this Neovim config on a fresh Linux machine (apt, dnf or pacman).
# Also pre-installs plugins (pinned by lazy-lock.json), LSPs, formatters and treesitter parsers.
set -euo pipefail

if [[ "$(uname -s)" != Linux ]]; then
  echo "install.sh is for Linux. On macOS, install neovim, lazygit, ripgrep, node, python and dotnet with Homebrew." >&2
  exit 1
fi

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bin_dir="$HOME/.local/bin"
opt_dir="$HOME/.local/opt"
sudo=""
[[ $EUID -ne 0 ]] && sudo="sudo"

case "$(uname -m)" in
  x86_64) arch=x86_64 ;;
  aarch64 | arm64) arch=arm64 ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

step=0
total_steps=8
if command -v fc-cache >/dev/null; then
  total_steps=9
fi
step_name=""
step() {
  step=$((step + 1))
  step_name="$1"
  printf '\n[%d/%d] %s\n' "$step" "$total_steps" "$step_name"
}
trap 'echo "install.sh failed during [$step/$total_steps] $step_name. Fix the error above and re-run; finished steps are skipped." >&2' ERR

latest_tag() { # GitHub redirects /releases/latest to /releases/tag/<tag>; avoids the rate-limited API
  curl -fsSLo /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" | sed 's|.*/||'
}

step "System packages"
# Mason needs node (npm), python (pypi), unzip and a JDK; nvim-treesitter needs a C compiler, curl and tar.
# clangd comes from the distro because Mason has no Linux arm64 build of it.
if command -v apt-get >/dev/null; then
  $sudo apt-get update
  $sudo apt-get install -y git curl tar gzip xz-utils unzip build-essential ripgrep \
    python3 python3-venv python3-pip nodejs npm default-jdk-headless libicu-dev clangd
elif command -v dnf >/dev/null; then
  $sudo dnf install -y git curl tar gzip xz unzip gcc gcc-c++ make ripgrep \
    python3 python3-pip nodejs npm java-latest-openjdk-devel libicu clang-tools-extra
elif command -v pacman >/dev/null; then
  $sudo pacman -Syu --needed --noconfirm git curl tar gzip xz unzip base-devel ripgrep \
    python python-pip nodejs npm jdk-openjdk icu clang
else
  echo "No supported package manager (apt, dnf, pacman) found." >&2
  exit 1
fi

mkdir -p "$bin_dir" "$opt_dir"

step "Neovim (latest stable)"
# Distro packages are often older than LazyVim's minimum, so use the official release
nvim_version="$(latest_tag neovim/neovim)"
if [[ "$("$opt_dir/nvim/bin/nvim" --version 2>/dev/null | head -1)" == "NVIM $nvim_version" ]]; then
  echo "Neovim $nvim_version is already installed"
else
  rm -rf "$opt_dir/nvim"
  mkdir -p "$opt_dir/nvim"
  curl -fL --progress-bar "https://github.com/neovim/neovim/releases/download/$nvim_version/nvim-linux-$arch.tar.gz" |
    tar -xz -C "$opt_dir/nvim" --strip-components=1
fi
# /usr/local/bin comes before /usr/bin in every shell's default PATH, so a distro nvim can't shadow this one
$sudo ln -sf "$opt_dir/nvim/bin/nvim" /usr/local/bin/nvim

step "lazygit"
lazygit_version="$(latest_tag jesseduffield/lazygit)"
if [[ "$("$bin_dir/lazygit" --version 2>/dev/null)" == *"version=${lazygit_version#v},"* ]]; then
  echo "lazygit $lazygit_version is already installed"
else
  curl -fL --progress-bar "https://github.com/jesseduffield/lazygit/releases/download/$lazygit_version/lazygit_${lazygit_version#v}_Linux_$arch.tar.gz" |
    tar -xz -C "$bin_dir" lazygit
fi

step ".NET SDK (LTS)"
# dotnet-install.sh skips the download when this version is already installed
curl -fsSL https://dot.net/v1/dotnet-install.sh | bash -s -- --channel LTS --install-dir "$HOME/.dotnet"

if command -v fc-cache >/dev/null; then
  step "JetBrainsMono Nerd Font"
  font_dir="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
  if compgen -G "$font_dir/*.ttf" >/dev/null; then
    echo "Font is already installed"
  else
    mkdir -p "$font_dir"
    curl -fL --progress-bar https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz | tar -xJ -C "$font_dir"
    fc-cache -f "$font_dir" >/dev/null
  fi
fi

step "Shell PATH"
# shellcheck disable=SC2016 # $HOME/$PATH must expand when the rc file runs, not now
path_block='# >>> nvim-config >>>
export PATH="$HOME/.local/bin:$HOME/.dotnet:$HOME/.dotnet/tools:$PATH"
export DOTNET_ROOT="$HOME/.dotnet"
# <<< nvim-config <<<'
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  [[ -f "$rc" || "$rc" == "$HOME/.bashrc" ]] || continue
  grep -q '>>> nvim-config >>>' "$rc" 2>/dev/null || printf '\n%s\n' "$path_block" >>"$rc"
done
export PATH="$bin_dir:$HOME/.dotnet:$HOME/.dotnet/tools:$PATH"
export DOTNET_ROOT="$HOME/.dotnet"

step "Link config to ~/.config/nvim"
config_dir="$HOME/.config/nvim"
if [[ "$(realpath "$config_dir" 2>/dev/null)" != "$repo_dir" ]]; then
  if [[ -e "$config_dir" || -L "$config_dir" ]]; then
    backup="$config_dir.bak.$(date +%Y%m%d%H%M%S)"
    echo "Moving existing $config_dir to $backup"
    mv "$config_dir" "$backup"
  fi
  mkdir -p "$HOME/.config"
  ln -s "$repo_dir" "$config_dir"
fi

step "Plugins (versions from lazy-lock.json)"
nvim --headless "+Lazy! restore" +qa

step "Language servers, formatters and treesitter parsers"
# Loading these plugins makes LazyVim queue its Mason and parser installs; wait for them before exiting
tools_script="$(mktemp --suffix=.lua)"
cat >"$tools_script" <<'EOF'
require("lazy").load({ plugins = { "mason.nvim", "nvim-lspconfig", "nvim-treesitter" } })
local registry = require("mason-registry")
-- mason-lspconfig skips its ensure_installed step in headless mode, so run it explicitly
registry.refresh(vim.schedule_wrap(function()
  require("mason-lspconfig.features.ensure_installed")()
end))
local function mason_pending()
  local installing = 0
  for _, package in ipairs(registry.get_all_packages()) do
    if package:is_installing() then
      installing = installing + 1
    end
  end
  local installed = #registry.get_installed_package_names()
  io.stdout:write(("\rMason: %d installed, %d in progress   "):format(installed, installing))
  return installing
end
vim.wait(30000, function() return mason_pending() > 0 end, 500)
vim.wait(1800000, function() return mason_pending() == 0 end, 1000)
io.stdout:write("\n")
local treesitter = require("lazy.core.config").plugins["nvim-treesitter"]
local parsers = require("lazy.core.plugin").values(treesitter, "opts", false).ensure_installed
require("nvim-treesitter").install(parsers):wait(1800000)
vim.cmd("qa!")
EOF
nvim --headless "+luafile $tools_script"
rm -f "$tools_script"

echo
echo "Done. Open a new shell (or 'source ~/.bashrc') and run nvim."
if command -v fc-cache >/dev/null; then
  echo "Set your terminal font to 'JetBrainsMono Nerd Font Mono' for icons."
fi
