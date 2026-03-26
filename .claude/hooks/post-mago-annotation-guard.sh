#!/bin/bash
set -euo pipefail

input="$(cat)"
file="$(jq -r '.tool_input.file_path // .tool_input.path // empty' <<< "$input")"

# Only process PHP files
case "$file" in
  *.php) ;;
  *) exit 0 ;;
esac

# Skip vendor files — those are third-party and not under our control
case "$file" in
  vendor/*|*/vendor/*) exit 0 ;;
esac

[ -f "$file" ] || exit 0

# Check for @mago-expect or @mago-ignore annotations
found=""
details=""

if matches="$(grep -n '@mago-expect' "$file" 2>/dev/null)"; then
  found="@mago-expect"
  details="$matches"
fi

if matches="$(grep -n '@mago-ignore' "$file" 2>/dev/null)"; then
  if [ -n "$found" ]; then
    found="$found and @mago-ignore"
  else
    found="@mago-ignore"
  fi
  details="${details:+$details
}$matches"
fi

if [ -n "$found" ]; then
  msg="[POLICY VIOLATION] ${found} annotation(s) detected in ${file}:
${details}

This project PROHIBITS the use of @mago-expect and @mago-ignore annotations (see ADR: docs/ADR/20260322-allow-mago-ignore-for-slim-route-handlers.md).
You MUST:
1. Remove the ${found} annotation(s) you just wrote
2. Fix the underlying code issue that the annotation was suppressing
3. If the mago warning is unavoidable due to framework constraints, leave the warning as-is (do NOT suppress it)
Do NOT add @mago-expect or @mago-ignore to project source code."

  jq -Rn --arg msg "$msg" '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: $msg
    }
  }'
fi
