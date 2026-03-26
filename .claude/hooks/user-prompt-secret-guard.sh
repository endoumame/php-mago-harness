#!/bin/bash
# UserPromptSubmit hook: Block prompts containing API keys or tokens.
set -euo pipefail

prompt="$(jq -r '.prompt')"

if echo "$prompt" | grep -qiE '(sk-[a-zA-Z0-9]{20,}|xoxb-|ghp_|AKIA[A-Z0-9]{16})'; then
  echo '{"decision":"block","reason":"⚠️ API キーやトークンが含まれています。1Password などで管理してください。"}'
fi
