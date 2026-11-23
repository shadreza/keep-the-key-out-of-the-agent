#!/bin/sh
# Check this machine before step 5, and say what to change. It changes nothing
# and never prints a key.
#
#   sh scripts/preflight.sh
#
# Exit 0: ready. Exit 1: something to fix first (each line says what).
set -u
todo=0
ok() { echo "ok    $*"; }
fix() { echo "FIX   $*"; todo=1; }
note() { echo "note  $*"; }

# 1. box itself
if command -v box >/dev/null 2>&1; then
    ok "$(box --version)"
else
    fix "box isn't on PATH: run step 1, then open a new terminal"
fi

# 2. Claude Code must be the real program, not a wrapper. Box starts the file
#    that `claude` resolves to, and a version manager's wrapper (mise, asdf) or
#    an npm script won't take Claude Code's arguments.
claude_path=$(command -v claude 2>/dev/null || true)
if [ -z "$claude_path" ]; then
    fix "claude isn't on PATH: install Claude Code (curl -fsSL https://claude.ai/install.sh | bash)"
else
    real=$(readlink -f "$claude_path")
    case "$(basename "$real")" in
        claude|claude.exe)
            ok "Claude Code at $real" ;;
        *)
            if command -v mise >/dev/null 2>&1 && mise which claude >/dev/null 2>&1; then
                note "claude resolves to $real, mise's wrapper. In step 5, add: --option claude.path=\"\$(mise which claude)\""
            else
                fix "claude resolves to $real, not Claude Code itself. Install it with its native installer, or pass --option claude.path=/path/to/claude in step 5"
            fi ;;
    esac
fi

# 3. The key must be in this terminal before `box profile create` and `box run`.
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    ok "ANTHROPIC_API_KEY is set in this terminal (not shown)"
else
    fix "ANTHROPIC_API_KEY isn't set: run the set -a line that move-env-out.sh printed (step 4), in this terminal"
fi

# 4. Box's home folder. On btrfs, a new box stops with "its first-use contents
#    changed before the record write" (known gap 5).
box_home=${BOX_HOME:-$HOME/.strands/box}
dir=$box_home
while [ ! -e "$dir" ]; do dir=$(dirname "$dir"); done
fs=$(stat -f -c %T "$dir" 2>/dev/null || echo unknown)
if [ "$fs" = btrfs ]; then
    note "$box_home is on btrfs: a new box stops once. Run it again with the --box-id it prints (known gap 5)."
else
    ok "$box_home is on $fs"
fi

# 5. Telemetry, so you choose.
command -v box >/dev/null 2>&1 && note "$(box telemetry status 2>&1 | head -n 1) To turn it off: box telemetry off"

echo
if [ "$todo" = 0 ]; then echo "Ready for step 5."; else echo "Fix the FIX lines, then run this again."; fi
exit "$todo"
