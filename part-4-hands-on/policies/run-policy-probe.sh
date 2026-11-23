#!/bin/sh
# Try the rules in examples.dw with no model and no cost: a plain shell runs
# in a box with them, in a throwaway project, then the refusals are listed.
#
#   sh policies/run-policy-probe.sh
#
# Needs box and network access to example.com. The key below is fake.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
command -v box >/dev/null || { echo "box isn't installed: see step 1" >&2; exit 1; }

project=$(mktemp -d "${TMPDIR:-/tmp}/box-policy.XXXXXX")
trap 'rm -rf "$project"' EXIT
printf 'ANTHROPIC_API_KEY=sk-ant-fake-canary-not-a-real-key\n' > "$project/.env"
printf 'hello\n' > "$project/notes.txt"
cd "$project"

# On a btrfs home folder a new box stops once ("first-use contents changed");
# starting the same box again works (part-4-hands-on/known-gaps.md, gap 5).
run_box() {
    box run "$@" --no-banner </dev/null >out.log 2>&1 && return 0
    grep -q 'first-use contents changed' out.log || return 1
    again=$(sed -n 's/.*--box-id \(b-[0-9a-f]*\).*/\1/p' out.log | head -n 1)
    [ -n "$again" ] || return 1
    box run "$@" --box-id "$again" --no-banner </dev/null >out.log 2>&1
}

if ! run_box "$here/policy-probe.toml"; then
    grep -E 'error' out.log >&2 || tail -n 5 out.log >&2
    echo "the box didn't start: see known-gaps.md" >&2
    exit 1
fi
grep -E '^[0-9.]+ ' out.log
echo
grep -E 'policy denied' out.log | sed "s#$project#~/src/my-app#g"
id=$(sed -n 's/.*with box ID \(b-[0-9a-f]*\).*/\1/p' out.log | head -n 1)
echo
echo "== box runs history $id --deny"
box runs history "$id" --deny | sed "s#$project#~/src/my-app#g"
