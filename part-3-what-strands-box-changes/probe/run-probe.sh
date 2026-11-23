#!/bin/sh
# See what a Strands Box does, with no model and no cost: run a plain shell
# in a box twice, first with probe-open.toml and then with probe-deny.toml,
# in a throwaway project that holds a fake key.
#
#   sh run-probe.sh
#
# Needs box (https://github.com/strands-agents/box). The key below is fake on
# purpose. Never put a real key in this script.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
command -v box >/dev/null || { echo "box isn't installed: see part-4-hands-on, step 1" >&2; exit 1; }

# The "real" key, as Box sees it in your shell. Fake, so it shows what the
# agent gets in its place.
ANTHROPIC_API_KEY=sk-ant-stand-in-for-your-real-key
export ANTHROPIC_API_KEY

project=$(mktemp -d "${TMPDIR:-/tmp}/box-probe.XXXXXX")
trap 'rm -rf "$project"' EXIT
printf 'ANTHROPIC_API_KEY=sk-ant-fake-canary-not-a-real-key\n' > "$project/.env"
cd "$project"

echo "Your shell holds: $ANTHROPIC_API_KEY"
echo "The project's .env holds a fake canary key."
for probe in probe-open probe-deny; do
    echo
    echo "== box run $probe.toml"
    rm -f hello.txt
    # The probe's lines start with a number; box's own lines go to the log.
    if ! box run "$here/$probe.toml" --no-banner </dev/null >out.log 2>&1; then
        grep -E 'error' out.log >&2 || tail -n 5 out.log >&2
        echo "the box didn't start: see part-4-hands-on/known-gaps.md" >&2
        exit 1
    fi
    grep -E '^[1-4]\. ' out.log
done
