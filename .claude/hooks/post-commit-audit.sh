#!/bin/bash
# Post-commit quality audit hook for Claude Code
# Runs linters + design system checks on committed files.
# Returns results via additionalContext so Claude actually sees them.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only trigger on git commit commands
if [[ ! "$COMMAND" =~ git[[:space:]]+commit ]]; then
  exit 0
fi

# Get files changed in the most recent commit
FILES=$(git diff --name-only HEAD~1 HEAD 2>/dev/null)
if [ -z "$FILES" ]; then
  exit 0
fi

# Separate files by type
TSX_FILES=$(echo "$FILES" | grep '\.tsx$' || true)
TS_FILES=$(echo "$FILES" | grep '\.ts$' || true)
ALL_TS=$(echo -e "${TSX_FILES}\n${TS_FILES}" | sed '/^$/d' || true)
RB_FILES=$(echo "$FILES" | grep '\.rb$' || true)

FAILURES=0
PASSES=0
FAILURE_DETAILS=""
PASS_DETAILS=""

check() {
  local label="$1"
  local result="$2"
  local detail="$3"

  if [ "$result" = "PASS" ]; then
    PASSES=$((PASSES + 1))
    PASS_DETAILS="${PASS_DETAILS}  ✅ ${label}\n"
  else
    FAILURES=$((FAILURES + 1))
    FAILURE_DETAILS="${FAILURE_DETAILS}  ❌ ${label}\n"
    if [ -n "$detail" ]; then
      FAILURE_DETAILS="${FAILURE_DETAILS}$(echo "$detail" | head -10 | sed 's/^/     /')\n"
    fi
  fi
}

# ─── Linters ─────────────────────────────────────────────

if [ -n "$ALL_TS" ]; then
  ESLINT_OUT=$(echo "$ALL_TS" | xargs npx eslint --no-warn-ignored 2>&1 || true)
  if echo "$ESLINT_OUT" | grep -q "error"; then
    check "ESLint" "FAIL" "$ESLINT_OUT"
  else
    check "ESLint" "PASS"
  fi
else
  check "ESLint (no .ts/.tsx files)" "PASS"
fi

if [ -n "$ALL_TS" ]; then
  TSC_OUT=$(npx tsc --noEmit 2>&1 || true)
  TSC_RELEVANT=""
  for f in $ALL_TS; do
    MATCH=$(echo "$TSC_OUT" | grep "^$f" || true)
    if [ -n "$MATCH" ]; then
      TSC_RELEVANT="${TSC_RELEVANT}${MATCH}\n"
    fi
  done
  if [ -z "$TSC_RELEVANT" ]; then
    check "TypeScript" "PASS"
  else
    check "TypeScript" "FAIL" "$(echo -e "$TSC_RELEVANT")"
  fi
else
  check "TypeScript (no .ts/.tsx files)" "PASS"
fi

if [ -n "$RB_FILES" ]; then
  RUBOCOP_OUT=$(echo "$RB_FILES" | xargs bundle exec rubocop --force-exclusion --format simple 2>&1 || true)
  if echo "$RUBOCOP_OUT" | grep -q "no offenses detected"; then
    check "RuboCop" "PASS"
  elif echo "$RUBOCOP_OUT" | grep -qE "[0-9]+ offense"; then
    check "RuboCop" "FAIL" "$RUBOCOP_OUT"
  else
    check "RuboCop" "PASS"
  fi
else
  check "RuboCop (no .rb files)" "PASS"
fi

# ─── Design System Checks (.tsx files) ───────────────────

if [ -n "$TSX_FILES" ]; then
  HITS=$(echo "$TSX_FILES" | xargs grep -n '\(bg\|text\|border\|shadow\)-\[hsl' 2>/dev/null || true)
  [ -z "$HITS" ] && check "No hardcoded HSL colors" "PASS" || check "No hardcoded HSL — use design tokens" "FAIL" "$HITS"

  HITS=$(echo "$TSX_FILES" | xargs grep -n 'shadow-\[' 2>/dev/null || true)
  [ -z "$HITS" ] && check "No hardcoded shadows" "PASS" || check "No hardcoded shadows — use shadow-sm/md" "FAIL" "$HITS"

  HITS=$(echo "$TSX_FILES" | xargs grep -n 'rounded-\(xl\|lg\|md\|2xl\|3xl\)' 2>/dev/null || true)
  [ -z "$HITS" ] && check "Border radius = rounded (4px)" "PASS" || check "Border radius must be rounded (4px)" "FAIL" "$HITS"

  HITS=$(echo "$TSX_FILES" | xargs grep -n 'text-\[[0-9]*px\]' 2>/dev/null | grep -v 'text-\[1[2-9]px\]\|text-\[[2-9][0-9]px\]' || true)
  [ -z "$HITS" ] && check "No text below 12px" "PASS" || check "Text below 12px minimum" "FAIL" "$HITS"

  HITS=$(echo "$TSX_FILES" | xargs grep -n '\(bg\|text\|border\)-[a-z-]*/[0-9]' 2>/dev/null || true)
  [ -z "$HITS" ] && check "No opacity modifiers on tokens" "PASS" || check "No opacity modifiers on tokens" "FAIL" "$HITS"

  HITS=$(echo "$TSX_FILES" | xargs grep -n '<button\b\|<input\b' 2>/dev/null || true)
  [ -z "$HITS" ] && check "No raw <button>/<input>" "PASS" || check "Raw HTML — use shadcn Button/Input" "FAIL" "$HITS"

  HITS=$(echo "$TSX_FILES" | xargs grep -n 'toLocaleDateString\|toLocaleTimeString\|\.toISOString\|new Date(' 2>/dev/null || true)
  [ -z "$HITS" ] && check "No frontend date formatting" "PASS" || check "Dates should come formatted from server" "FAIL" "$HITS"

  HITS=$(echo "$TSX_FILES" | xargs grep -n '\.reduce\s*(' 2>/dev/null || true)
  [ -z "$HITS" ] && check "No .reduce() display logic" "PASS" || check ".reduce() — aggregate on server" "FAIL" "$HITS"

  HITS=$(echo "$TSX_FILES" | xargs grep -n '`/[a-z].*\${' 2>/dev/null || true)
  [ -z "$HITS" ] && check "No hardcoded routes" "PASS" || check "Hardcoded routes — use path props" "FAIL" "$HITS"
fi

# ─── Backend Checks (.rb files) ──────────────────────────

if [ -n "$RB_FILES" ]; then
  CONTROLLER_FILES=$(echo "$RB_FILES" | grep 'controllers/' || true)
  if [ -n "$CONTROLLER_FILES" ]; then
    HITS=$(echo "$CONTROLLER_FILES" | xargs grep -n '\(Incident\|Property\|User\)\.find\b' 2>/dev/null | grep -v 'find_visible\|find_by' || true)
    [ -z "$HITS" ] && check "No unscoped .find()" "PASS" || check "Unscoped .find() — use scoped query" "FAIL" "$HITS"

    HITS=$(echo "$RB_FILES" | xargs grep -n '\.permit!' 2>/dev/null || true)
    [ -z "$HITS" ] && check "No .permit!" "PASS" || check ".permit! — whitelist attributes" "FAIL" "$HITS"
  fi
fi

# ─── Build output and return as JSON ─────────────────────

FILE_LIST=$(echo "$FILES" | sed 's/^/  /' | tr '\n' '|' | sed 's/|/\\n/g')

if [ "$FAILURES" -gt 0 ]; then
  CONTEXT="POST-COMMIT AUDIT: ❌ ${FAILURES} FAILED / ${PASSES} passed

Files: $(echo "$FILES" | tr '\n' ', ' | sed 's/,$//')

Failures:
$(echo -e "$FAILURE_DETAILS")
FIX ALL FAILURES before moving to next task. See docs/CODE_QUALITY.md."

  jq -n --arg ctx "$CONTEXT" '{
    "hookSpecificOutput": {
      "hookEventName": "PostToolUse",
      "additionalContext": $ctx
    }
  }'
else
  CONTEXT="POST-COMMIT AUDIT: ✅ ALL ${PASSES} CHECKS PASSED

Files: $(echo "$FILES" | tr '\n' ', ' | sed 's/,$//')

Manual review: server sends display-ready data? Types match props? Auth tests cover cross-org?"

  jq -n --arg ctx "$CONTEXT" '{
    "hookSpecificOutput": {
      "hookEventName": "PostToolUse",
      "additionalContext": $ctx
    }
  }'
fi

exit 0
