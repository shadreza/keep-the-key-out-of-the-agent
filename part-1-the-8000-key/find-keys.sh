#!/bin/sh
# Look at a project the way a coding agent sees it: which .env files sit in
# its reach, whether git would track them, and whether a key's name shows up
# anywhere in the history. It prints paths, commit IDs and names only, never
# a value.
#
#   sh find-keys.sh ~/src/my-app
#   sh find-keys.sh ~/src/my-app MY_KEY OTHER_KEY   # your own variable names
#
# Nothing is changed. Exit 0: nothing found. Exit 1: something to look at.
set -eu

project=${1:?usage: sh find-keys.sh PROJECT_DIR [VARIABLE_NAME ...]}
shift
cd "$project"
[ "$#" -gt 0 ] || set -- OPENAI_API_KEY ANTHROPIC_API_KEY AWS_SECRET_ACCESS_KEY
found=0

echo "== .env files the agent can read in $(pwd)"
files=$(find . -maxdepth 3 -name '.env*' -not -path '*/.git/*' -not -path '*/node_modules/*' | sort)
if [ -z "$files" ]; then
    echo "(none)"
else
    echo "$files"
    found=1
fi
echo

if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "not a git repository: skipping the git checks"
    exit "$found"
fi

echo "== would git track them?"
if [ -z "$files" ]; then
    echo "(no .env files)"
else
    echo "$files" | while IFS= read -r f; do
        if git check-ignore -q "$f"; then
            echo "ignored      $f"
        else
            echo "NOT ignored  $f   (one 'git add .' puts it in the history)"
        fi
    done
fi
echo

echo "== .env files ever committed, on any branch"
committed=$(git log --all --format= --name-only --diff-filter=A -- '.env' '*/.env' '.env.*' '*/.env.*' 2>/dev/null | grep -v '^$' | sort -u || true)
if [ -z "$committed" ]; then
    echo "(none)"
else
    echo "$committed"
    echo "a key in any of these is in every clone, even if the file was deleted later"
    found=1
fi
echo

echo "== commits that added or removed these names: $*"
named=0
for name in "$@"; do
    hits=$(git log --all --format='%h %ad %s' --date=short -S"$name" 2>/dev/null || true)
    if [ -n "$hits" ]; then
        echo "-- $name"
        echo "$hits"
        found=1 named=1
    fi
done
[ "$named" = 1 ] || echo "(none)"
echo

if [ "$found" = 1 ]; then
    echo "Write down where each key sits, who owns it, and whether it has a spending cap."
    echo "If a real key is in the history, rotate it first."
fi
exit "$found"
