#!/bin/bash
# ============================================================================
# 1-pack-macos.sh
# Run on macOS (the SOURCE machine) — packs EVERYTHING into one archive
# Output: ~/Desktop/vscode-migration.tar.gz
# ============================================================================
set -e

echo "=========================================="
echo "  VScode Full Migration — PACK (macOS)"
echo "=========================================="
echo ""

# 1. Quit VScode so files aren't locked
echo "[1/5] Quitting VScode..."
osascript -e 'quit app "Visual Studio code"' 2>/dev/null || true
sleep 2

user_DIR=~/library/application\ Support/code/user
EXT_DIR=~/.vscode/extensions
OUTPUT=~/Desktop/vscode-migration.tar.gz
WORK=/tmp/vscode-migrate-pack

# 2. Clean work folder
rm -rf "$WORK"
mkdir -p "$WORK"

echo "[2/5] Copying user folder (settings, keybindings, snippets, globalStorage)..."
# Copy the entire user folder, excluding caches/logs/junk
cd "$user_DIR"
tar cf "$WORK/user.tar" \
  --exclude='.DS_Store' \
  --exclude='._*' \
  --exclude='__MACOSX' \
  --exclude='*.log' \
  --exclude='CachedExtensions' \
  --exclude='cachedExtensionVSIXs' \
  --exclude='logs' \
  settings.json keybindings.json snippets 2>/dev/null || true

# Add globalStorage and workspaceStorage separately (skip on errors)
echo "[3/5] Packing globalStorage + workspaceStorage..."
tar rf "$WORK/user.tar" \
  --exclude='.DS_Store' \
  --exclude='._*' \
  --exclude='__MACOSX' \
  --exclude='*.log' \
  globalStorage 2>/dev/null || echo "  (some globalStorage files skipped)"

# workspaceStorage is optional — comment out the next line to skip
tar rf "$WORK/user.tar" \
  --exclude='.DS_Store' \
  --exclude='._*' \
  --exclude='__MACOSX' \
  workspaceStorage 2>/dev/null || echo "  (workspaceStorage skipped — that's OK, it's just cache)"

echo "[4/5] Packing extensions folder (the actual extension code)..."
cd ~/.vscode
tar cf "$WORK/extensions.tar" \
  --exclude='.DS_Store' \
  --exclude='._*' \
  --exclude='__MACOSX' \
  --exclude='*.log' \
  extensions 2>/dev/null || echo "  (some extensions skipped)"

# Also export extensions list as a fallback
echo "  → Exporting extension list as fallback..."
code --list-extensions > "$WORK/extensions-list.txt" 2>/dev/null || true

# 3. Combine everything into one gzipped tar
echo "[5/5] Compressing everything into one file..."
cd "$WORK"
tar czf "$OUTPUT" user.tar extensions.tar extensions-list.txt

# Cleanup
rm -rf "$WORK"

size=$(du -h "$OUTPUT" | cut -f1)
echo ""
echo "=========================================="
echo "  ✅ DONE!"
echo "=========================================="
echo ""
echo "Archive created: $OUTPUT"
echo "size: $size"
echo ""
echo "Next steps:"
echo "  1. Copy vscode-migration.tar.gz to your Windows machine"
echo "     (USB drive, network share, Google Drive, etc.)"
echo "  2. Place it on the Windows Desktop"
echo "  3. Run 2-unpack-windows.ps1 on Windows as Administrator"
echo ""
