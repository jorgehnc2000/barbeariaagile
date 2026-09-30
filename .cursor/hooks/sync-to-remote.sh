#!/usr/bin/env bash
# After Agent finishes: commit tracked work (respects .gitignore) and push to GitHub.
root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$root" || exit 0
branch="$(git symbolic-ref --short HEAD 2>/dev/null)" || exit 0
git remote get-url origin >/dev/null 2>&1 || exit 0

if [[ -n "$(git status --porcelain)" ]]; then
  git add -A
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  git commit -m "chore: auto-sync from Cursor ($ts)" >/dev/null 2>&1 || true
fi

git push -u origin "$branch" >/dev/null 2>&1 || true
exit 0
