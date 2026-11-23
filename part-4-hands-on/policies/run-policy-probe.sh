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

if ! box run "$here/policy-probe.toml" --no-banner </dev/null >out.log 2>&1; then
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
