#!/bin/sh
# Move a project's .env out of the project, into a file only you can read.
#
#   sh move-env-out.sh ~/src/my-app
#
# It moves ~/src/my-app/.env to ~/.config/agent-secrets/my-app.env (mode 600)
# and refuses to overwrite a file that is already there. Nothing is printed
# from the file itself.
set -eu

project=${1:?usage: sh move-env-out.sh PROJECT_DIR}
project=$(cd "$project" && pwd)
name=$(basename "$project")
src="$project/.env"
dir="${AGENT_SECRETS_DIR:-$HOME/.config/agent-secrets}"
dst="$dir/$name.env"

[ -f "$src" ] || { echo "no .env in $project, nothing to move"; exit 0; }
[ ! -e "$dst" ] || { echo "refusing: $dst already exists" >&2; exit 1; }
case "$dir/" in "$project"/*) echo "refusing: $dir is inside the project" >&2; exit 1 ;; esac

mkdir -p "$dir"
chmod 700 "$dir"
mv "$src" "$dst"
chmod 600 "$dst"
echo "moved $src"
echo "   to $dst (mode 600)"
echo "load it in the terminal you run box from:"
echo "   set -a; . \"$dst\"; set +a"
