#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
TARGET="${HOME}/INVESTIGO_REPO"
if [ ! -d "$TARGET/.git" ]; then
  echo "ERROR: $TARGET is not an INVESTIGO git repository."
  exit 1
fi
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
rsync -a --exclude '.git' --exclude 'apply_to_investigo.sh' "$SOURCE_DIR/" "$TARGET/"
echo "Files copied to $TARGET. No commit or push was performed."
