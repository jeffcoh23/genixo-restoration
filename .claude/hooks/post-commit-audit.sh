#!/bin/bash
# Post-commit quality audit hook for Claude Code
# Runs linters + custom design system checks on committed files.
# Claude must fix any FAILs before moving to the next task.

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

check() {
  local label="$1"
  local result="$2"
  local detail="$3"

  if [ "$result" = "PASS" ]; then
    PASSES=$((PASSES + 1))
    echo "  ✅ $label"
  else
    FAILURES=$((FAILURES + 1))
    echo "  ❌ $label"
    if [ -n "$detail" ]; then
      echo "$detail" | head -20 | sed 's/^/     /'
    fi
  fi
}

echo ""
echo "═══════════════════════════════════════════════════════"
echo " POST-COMMIT QUALITY AUDIT"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Files committed:"
echo "$FILES" | sed 's/^/  /'
echo ""

# ─── Linters ─────────────────────────────────────────────
echo "─── Linters ──────────────────────────────────────────"
echo ""

# ESLint (on committed .tsx/.ts files)
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

# TypeScript (full project — fast with incremental, filters to committed files)
if [ -n "$ALL_TS" ]; then
  TSC_OUT=$(npx tsc --noEmit 2>&1 || true)
  # Filter to only errors in committed files
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

# RuboCop (on committed .rb files)
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

echo ""

# ─── Design System Checks (.tsx files) ───────────────────
if [ -n "$TSX_FILES" ]; then
  echo "─── Design System (.tsx) ───────────────────────────"
  echo ""

  # Hardcoded HSL colors
  HITS=$(echo "$TSX_FILES" | xargs grep -n '\(bg\|text\|border\|shadow\)-\[hsl' 2>/dev/null || true)
  if [ -z "$HITS" ]; then
    check "No hardcoded HSL colors" "PASS"
  else
    check "No hardcoded HSL — use design tokens" "FAIL" "$HITS"
  fi

  # Hardcoded shadows
  HITS=$(echo "$TSX_FILES" | xargs grep -n 'shadow-\[' 2>/dev/null || true)
  if [ -z "$HITS" ]; then
    check "No hardcoded shadows" "PASS"
  else
    check "No hardcoded shadows — use shadow-sm/md" "FAIL" "$HITS"
  fi

  # Wrong border radius
  HITS=$(echo "$TSX_FILES" | xargs grep -n 'rounded-\(xl\|lg\|md\|2xl\|3xl\)' 2>/dev/null || true)
  if [ -z "$HITS" ]; then
    check "Border radius = rounded (4px)" "PASS"
  else
    check "Border radius must be rounded (4px)" "FAIL" "$HITS"
  fi

  # Sub-12px text
  HITS=$(echo "$TSX_FILES" | xargs grep -n 'text-\[[0-9]*px\]' 2>/dev/null | grep -v 'text-\[1[2-9]px\]\|text-\[[2-9][0-9]px\]' || true)
  if [ -z "$HITS" ]; then
    check "No text below 12px" "PASS"
  else
    check "Text below 12px minimum" "FAIL" "$HITS"
  fi

  # Opacity modifiers on tokens
  HITS=$(echo "$TSX_FILES" | xargs grep -n '\(bg\|text\|border\)-[a-z-]*/[0-9]' 2>/dev/null || true)
  if [ -z "$HITS" ]; then
    check "No opacity modifiers on tokens" "PASS"
  else
    check "No opacity modifiers on tokens" "FAIL" "$HITS"
  fi

  # Raw <button> or <input>
  HITS=$(echo "$TSX_FILES" | xargs grep -n '<button\b\|<input\b' 2>/dev/null || true)
  if [ -z "$HITS" ]; then
    check "No raw <button>/<input>" "PASS"
  else
    check "Raw HTML — use shadcn Button/Input" "FAIL" "$HITS"
  fi

  # Frontend date formatting
  HITS=$(echo "$TSX_FILES" | xargs grep -n 'toLocaleDateString\|toLocaleTimeString\|\.toISOString\|new Date(' 2>/dev/null || true)
  if [ -z "$HITS" ]; then
    check "No frontend date formatting" "PASS"
  else
    check "Dates should come formatted from server" "FAIL" "$HITS"
  fi

  # .reduce() for display logic
  HITS=$(echo "$TSX_FILES" | xargs grep -n '\.reduce\s*(' 2>/dev/null || true)
  if [ -z "$HITS" ]; then
    check "No .reduce() display logic" "PASS"
  else
    check ".reduce() — aggregate on server" "FAIL" "$HITS"
  fi

  # Hardcoded route construction
  HITS=$(echo "$TSX_FILES" | xargs grep -n '`/[a-z].*\${' 2>/dev/null || true)
  if [ -z "$HITS" ]; then
    check "No hardcoded routes" "PASS"
  else
    check "Hardcoded routes — use path props" "FAIL" "$HITS"
  fi

  echo ""
fi

# ─── Backend Checks (.rb files) ──────────────────────────
if [ -n "$RB_FILES" ]; then
  CONTROLLER_FILES=$(echo "$RB_FILES" | grep 'controllers/' || true)
  if [ -n "$CONTROLLER_FILES" ]; then
    echo "─── Backend Checks (.rb) ─────────────────────────"
    echo ""

    HITS=$(echo "$CONTROLLER_FILES" | xargs grep -n '\(Incident\|Property\|User\)\.find\b' 2>/dev/null | grep -v 'find_visible\|find_by' || true)
    if [ -z "$HITS" ]; then
      check "No unscoped .find()" "PASS"
    else
      check "Unscoped .find() — use scoped query" "FAIL" "$HITS"
    fi

    HITS=$(echo "$RB_FILES" | xargs grep -n '\.permit!' 2>/dev/null || true)
    if [ -z "$HITS" ]; then
      check "No .permit!" "PASS"
    else
      check ".permit! — whitelist attributes" "FAIL" "$HITS"
    fi

    echo ""
  fi
fi

# ─── Manual Review ───────────────────────────────────────
echo "─── Manual Review (Claude must verify) ───────────────"
echo ""
echo "  □ Server sends display-ready data (labels, not enums)"
echo "  □ TypeScript types match controller props"
echo "  □ Tests cover authorization (cross-org isolation)"
echo ""

# ─── Summary ─────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════"
if [ "$FAILURES" -gt 0 ]; then
  echo " RESULT: ❌ $FAILURES FAIL / $PASSES PASS"
  echo ""
  echo " FIX ALL FAILURES BEFORE MOVING TO THE NEXT TASK."
  echo "═══════════════════════════════════════════════════════"
else
  echo " RESULT: ✅ ALL $PASSES CHECKS PASSED"
  echo ""
  echo " Still verify manual review items above."
  echo "═══════════════════════════════════════════════════════"
fi

exit 0
