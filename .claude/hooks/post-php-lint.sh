#!/bin/bash
set -euo pipefail

input="$(cat)"
file="$(jq -r '.tool_input.file_path // .tool_input.path // empty' <<< "$input")"

# Only process PHP files
case "$file" in
  *.php) ;;
  *) exit 0 ;;
esac

cd "$CLAUDE_PROJECT_DIR"

# Format the file (suppress errors)
vendor/bin/mago fmt "$file" >/dev/null 2>&1 || true

# Lint + analyze: capture output containing warnings or errors regardless of exit code
diag=""
lint="$(vendor/bin/mago lint "$file" 2>&1 | head -20)" || true
if echo "$lint" | grep -qE '(error|warning|help)\['; then
  diag="$lint"
fi
analyze="$(vendor/bin/mago analyze "$file" 2>&1 | head -20)" || true
if echo "$analyze" | grep -qE '(error|warning|help)\['; then
  diag="$diag"$'\n'"$analyze"
fi

if [ -n "$diag" ]; then
  jq -Rn --arg msg "$diag" '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: $msg
    }
  }'
fi
