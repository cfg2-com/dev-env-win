#!/usr/bin/env bash

set -e

FZF_DIR="$HOME/.fzf"

echo "==> Setting up fzf via GitHub..."

# 1. Clone or update the repository
if [ ! -d "$FZF_DIR" ]; then
    echo "Cloning fzf repository..."
    git clone --depth 1 https://github.com/junegunn/fzf.git "$FZF_DIR"
else
    echo "fzf directory already exists. Pulling latest changes..."
    git -C "$FZF_DIR" pull
fi

# 2. Run the non-interactive install script
# --key-bindings : Enables Ctrl+R, Ctrl+T, Alt+C
# --completion   : Enables fuzzy tab completion (e.g. cd **<TAB>)
# --update-rc    : Appends the setup lines to ~/.bashrc automatically
echo "Running fzf installer..."
"$FZF_DIR/install" --key-bindings --completion --update-rc --no-zsh --no-fish

# 3. Source the updated profile for the current session
if [ -f "$HOME/.bashrc" ]; then
    echo "Sourcing ~/.bashrc for current session..."
    # Suppress output during source
    source "$HOME/.bashrc"
fi

echo -e "\n Setup complete! Keybindings and completion are active."