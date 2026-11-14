#!/usr/bin/env bash
# macOS only: requires gh and a GitHub repository that already exists.
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ $# -ne 1 ]]; then
  echo 'Usage: bash scripts/publish-github.sh OWNER/GlassNeedle' >&2
  exit 2
fi
REPO="$1"
if ! [[ "$REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  echo 'Expected OWNER/REPO; example: takhirovrozimuhammad/GlassNeedle' >&2
  exit 2
fi
command -v gh >/dev/null || { echo 'Install GitHub CLI (gh) first.' >&2; exit 1; }
gh auth status >/dev/null
# Never force push or overwrite an existing repository history.
if [[ -n "$(git status --porcelain 2>/dev/null || true)" ]] || ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [[ ! -d .git ]]; then git init -b main; fi
fi
if [[ -z "$(git remote 2>/dev/null)" ]]; then git remote add origin "https://github.com/$REPO.git"; fi
if [[ "$(git remote get-url origin)" != "https://github.com/$REPO.git" ]]; then
  echo 'Existing origin points to a different repository; refusing to change it.' >&2
  exit 1
fi
if git ls-remote --exit-code origin refs/heads/main >/dev/null 2>&1; then
  echo 'The target already has a main branch. Refusing to overwrite. Use a new empty repository.' >&2
  exit 1
fi
git add .gitignore .github LICENSE Info.plist Package.swift README.md RESEARCH.md Resources Sources scripts
git commit -m 'Initial GlassNeedle native macOS preview with DMG release workflow'
git branch -M main
git push -u origin main
echo "GitHub Actions builds on macOS and publishes the .dmg to https://github.com/$REPO/releases"
