#!/bin/sh
# The check from Box's limitations page, to run in the project after an
# agent's run and before any other command there.
#
#   sh after-run-check.sh ~/src/my-app
#
# It only reads: .git/config, the hooks that aren't samples, then
# git status --ignored and git diff. Read every line it prints.
set -eu
cd "${1:?usage: sh after-run-check.sh PROJECT_DIR}"

echo "== .git/config (look for core.hooksPath, core.fsmonitor, alias, filter, diff)"
cat .git/config
echo
echo "== hooks that are not samples (expect none you didn't add)"
hooks=$(ls .git/hooks 2>/dev/null | grep -v '\.sample$' || true)
echo "${hooks:-(none)}"
echo
# git itself runs core.fsmonitor and hooks, so stop before any git command
# when the config or the hooks hold something to read first.
if grep -Eiq 'hookspath|fsmonitor|^\[alias|^\[filter|^\[diff' .git/config || [ -n "$hooks" ]; then
    echo "STOP: read the lines above before running git here. Re-run with FORCE=1 once they're yours." >&2
    [ "${FORCE:-0}" = 1 ] || exit 2
fi
echo "== git status --ignored (ignored files the agent may have written show here only)"
git status --ignored --short
echo
echo "== git diff"
git diff --stat
