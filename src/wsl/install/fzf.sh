#!/usr/bin/env bash

set -e

FZF_DIR="$HOME/.fzf"
BASHRC="$HOME/.bashrc"

echo "==> Setting up fzf via GitHub..."

# 1. Clone or update the repository
if [ ! -d "$FZF_DIR" ]; then
    echo "Cloning fzf repository..."
    git clone --depth 1 https://github.com/junegunn/fzf.git "$FZF_DIR"
else
    echo "fzf directory already exists. Pulling latest changes..."
    git -C "$FZF_DIR" pull
fi

# 2. Download/build the fzf binary directly without running full setup
echo "Installing fzf binary..."
"$FZF_DIR/install" --bin

# 3. Clean up any previous fzf configurations from ~/.bashrc safely
if [ -f "$BASHRC" ]; then
    echo "Cleaning up old fzf entries in ~/.bashrc..."
    # Remove block marked by our custom comments
    sed -i '/# === fzf zero-latency config ===/,/# === end fzf config ===/d' "$BASHRC"
    # Remove legacy/standard fzf installer lines
    sed -i '/\.fzf\.bash/d' "$BASHRC"
fi

# 4. Inject zero-latency native bash bindings into ~/.bashrc
echo "Injecting zero-latency bindings into ~/.bashrc..."
cat << 'EOF' >> "$BASHRC"

# === fzf zero-latency config ===
if [[ ":$PATH:" != *":$HOME/.fzf/bin:"* ]]; then
    export PATH="$HOME/.fzf/bin:$PATH"
fi

if [[ $- == *i* ]]; then
    # Ctrl + R: Search command history
    bind -x '"\C-r": "READLINE_LINE=$(HISTTIMEFORMAT= history | fzf --height 40% --reverse +s --tac | sed -E '\''s/^[ ]*[0-9]+[ ]*//'\''); READLINE_POINT=${#READLINE_LINE}"'

    # Ctrl + T: Search files and insert selected path at cursor
    bind -x '"\C-t": "FZF_OUT=$(fzf --height 40% --reverse); if [ -n \"$FZF_OUT\" ]; then READLINE_LINE=\"${READLINE_LINE:0:$READLINE_POINT}$FZF_OUT${READLINE_LINE:$READLINE_POINT}\"; READLINE_POINT=$((READLINE_POINT + ${#FZF_OUT})); fi"'
fi
# === end fzf config ===
EOF

echo -e "\nSetup complete! Zero-latency keybindings injected into ~/.bashrc."
echo "Use Ctrl + R to search command history and Ctrl + T to search files."