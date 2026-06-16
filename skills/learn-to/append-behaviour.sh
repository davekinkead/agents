#!/usr/bin/env bash
set -euo pipefail
NOTES_DIR="$HOME/.agents"
NOTES_FILE="$NOTES_DIR/behaviour.md"
mkdir -p "$NOTES_DIR"
# Read stdin into variable
entry="$(cat -)"
lockfile="$NOTES_FILE.lock"
exec 9>"$lockfile"
if command -v flock >/dev/null 2>&1; then
  flock -x 9
  printf "%s\n\n" "$entry" >>"$NOTES_FILE"
  flock -u 9
else
  # fallback without flock
  printf "%s\n\n" "$entry" >>"$NOTES_FILE"
fi
exec 9>&-
echo "Appended note to $NOTES_FILE" 
