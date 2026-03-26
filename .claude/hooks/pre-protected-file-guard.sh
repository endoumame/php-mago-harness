#!/bin/bash
# PreToolUse hook: Block edits to protected config files.
# Protected files should not be modified to work around linter/formatter issues.
set -euo pipefail

input="$(cat)"
FILE="$(jq -r '.tool_input.file_path // .tool_input.path // empty' <<< "$input")"

PROTECTED="mago.toml phpunit.xml composer.lock .env"

for p in $PROTECTED; do
  case "$FILE" in
    *"$p"*)
      echo "BLOCKED: $FILE is a protected config file. Fix the code, not the linter/formatter config." >&2
      exit 2
      ;;
  esac
done
