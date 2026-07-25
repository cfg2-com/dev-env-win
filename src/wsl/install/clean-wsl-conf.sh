#!/usr/bin/env bash

# This script cleans up the PATH environment variable in WSL to avoid conflicts with Windows paths,
# speeds up fzf by preventing Windows directory crawling, and disables fstab processing to eliminate startup mount errors.
# Also disables fstab processing to eliminate startup mount errors. Use systemd mount units instead of fstab for mounting drives.

cat << 'EOF' > fix-and-restart-wsl.sh
#!/bin/bash

# 1. Ensure /etc/wsl.conf contains PATH cleanup and disables fstab processing
sudo bash -c 'cat << "WSLCONF" >> /etc/wsl.conf

[interop]
appendWindowsPath = false

[automount]
enabled = true
mountFsTab = false
WSLCONF'

echo "Updated /etc/wsl.conf with interop and automount fixes."
echo "Shutting down WSL in 3 seconds..."
echo "If shutdown fails, please manually run 'wsl --shutdown' in Windows PowerShell."
sleep 3

# 2. Call Windows PowerShell from WSL to trigger the shutdown
powershell.exe -Command "wsl --shutdown"
EOF

chmod +x fix-and-restart-wsl.sh
./fix-and-restart-wsl.sh

rm fix-and-restart-wsl.sh