#!/data/data/com.termux/files/usr/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: bash push_to_github.sh https://github.com/YOUR_USERNAME/investigation-process-mobile.git"
  exit 1
fi

REPO_URL="$1"

git config --global user.name "Kalna Police"
git config --global user.email "kalnapolice@gmail.com"

if [ ! -d .git ]; then
  git init
fi

git branch -M main
git add .

git commit -m "Initial Investigation Process Mobile MVP" || echo "No new changes to commit. Continuing..."

git remote remove origin 2>/dev/null || true
git remote add origin "$REPO_URL"
git push -u origin main

echo "Done. Open GitHub Actions to download the debug APK artifact."
