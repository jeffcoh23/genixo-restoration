#!/bin/bash
# Post-commit quality audit hook for Claude Code
# Runs automated checks on committed files and prints PASS/FAIL results.
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
RB_FILES=$(echo "$FILES" | grep '\.rb$' || true)
TEST_FILES=$(echo "$FILES" | grep '^test/' || true)

FAILURES=0
PASSES=0

check() {
  local label="$1"
  local result="$2"  # "PASS" or "FAIL"
  local detail="$3"  # optional detail for failures

  if [ "$result" = "PASS" ]; then
    PASSES=$((PASSES + 1))
    echo "  ✅ $label"
  else
    FAILURES=$((FAILURES + 1))
    echo "  ❌ $label"
    if [ -n "$detail" ]; then
      echo "$detail" | sed 's/^/     /'
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

# ─── Frontend checks (.tsx files) ────────────────────────
if [ -n "$TSX_FILES" ]; then
  echo "─── Frontend (.tsx) ────────────────────────────────"
  echo ""

  # Check 1: No hardcoded colors (bg-[hsl...], text-[hsl...], border-[hsl...])
  HITS=$(echo "$TSX_FILES" | xargs grep -n '\(bg\|text\|border\|shadow\)-\[hsl' 2>/dev/null || true)
  if [ -z "$HITS" ]; then
    check "No hardcoded HSL colors" "PASS"
  else
    check "No hardcoded HSL colors — use design tokens" "FAIL" "$HITS"
  fi

  # Check 2: No hardcoded shadows (shadow-[...])
  HITS=$(echo "$TSX_FILES" | xargs grep -n 'shadow-\[' 2>/dev/null || true)
  if [ -z "$HITS" ]; then
    check "No hardcoded shadows" "PASS"
  else
    check "No hardcoded shadows — use shadow-sm or shadow-md" "FAIL" "$HITS"
  fi

  # Check 3: No wrong border radius (rounded-xl, rounded-lg, rounded-md, rounded-2xl)
  # Allow: rounded, rounded-full, rounded-none
  HITS=$(echo "$TSX_FILES" | xargs grep -n 'rounded-\(xl\|lg\|md\|2xl\|3xl\)' 2>/dev/null || true)
  if [ -z "$HITS" ]; then
    check "Border radius uses rounded (4px)" "PASS"
  else
    check "Border radius must be rounded (4px) per DESIGN.md" "FAIL" "$HITS"
  fi

  # Check 4: No sub-12px text (text-[10px], text-[11px], text-[9px], etc.)
  HITS=$(echo "$TSX_FILES" | xargs grep -n 'text-\[[0-9]*px\]' 2>/dev/null | grep -v 'text-\[1[2-9]px\]\|text-\[[2-9][0-9]px\]' || true)
  if [ -z "$HITS" ]; then
    check "No text below 12px minimum" "PASS"
  else
    check "Text below 12px minimum per DESIGN.md" "FAIL" "$HITS"
  fi

  # Check 5: No opacity modifiers on design tokens (bg-muted/80, text-foreground/50, etc.)
  HITS=$(echo "$TSX_FILES" | xargs grep -n '\(bg\|text\|border\)-[a-z-]*/[0-9]' 2>/dev/null || true)
  if [ -z "$HITS" ]; then
    check "No opacity modifiers on tokens" "PASS"
  else
    check "No opacity modifiers on design tokens" "FAIL" "$HITS"
  fi

  # Check 6: No raw <button> (should use shadcn Button)
  HITS=$(echo "$TSX_FILES" | xargs grep -n '<button\b' 2>/dev/null || true)
  if [ -z "$HITS" ]; then
    check "No raw <button> — uses shadcn Button" "PASS"
  else
    check "Raw <button> found — use shadcn Button component" "FAIL" "$HITS"
  fi

  # Check 7: No raw <input> (should use shadcn Input)
  HITS=$(echo "$TSX_FILES" | xargs grep -n '<input\b' 2>/dev/null || true)
  if [ -z "$HITS" ]; then
    check "No raw <input> — uses shadcn Input" "PASS"
  else
    check "Raw <input> found — use shadcn Input component" "FAIL" "$HITS"
  fi

  # Check 8: No frontend date formatting (toLocaleDateString, .toISOString, new Date(), .format(, strftime)
  HITS=$(echo "$TSX_FILES" | xargs grep -n 'toLocaleDateString\|toLocaleTimeString\|\.toISOString\|new Date(' 2>/dev/null || true)
  if [ -z "$HITS" ]; then
    check "No frontend date formatting" "PASS"
  else
    check "Frontend date formatting — dates should come formatted from server" "FAIL" "$HITS"
  fi

  # Check 9: No .reduce/.filter/.map chains for display logic
  HITS=$(echo "$TSX_FILES" | xargs grep -n '\.reduce\s*(' 2>/dev/null || true)
  if [ -z "$HITS" ]; then
    check "No .reduce() for display logic" "PASS"
  else
    check ".reduce() found — display aggregation should happen on server" "FAIL" "$HITS"
  fi

  # Check 10: No hardcoded route construction (template literals with /incidents/ etc.)
  HITS=$(echo "$TSX_FILES" | xargs grep -n '`/[a-z].*\${' 2>/dev/null || true)
  if [ -z "$HITS" ]; then
    check "No hardcoded route construction" "PASS"
  else
    check "Hardcoded routes — use server-provided path props" "FAIL" "$HITS"
  fi

  echo ""
fi

# ─── Backend checks (.rb files) ──────────────────────────
if [ -n "$RB_FILES" ]; then
  echo "─── Backend (.rb) ──────────────────────────────────"
  echo ""

  # Check: No Incident.find or Property.find (should use scoped queries)
  CONTROLLER_FILES=$(echo "$RB_FILES" | grep 'controllers/' || true)
  if [ -n "$CONTROLLER_FILES" ]; then
    HITS=$(echo "$CONTROLLER_FILES" | xargs grep -n '\(Incident\|Property\|User\)\.find\b' 2>/dev/null | grep -v 'find_visible\|find_by' || true)
    if [ -z "$HITS" ]; then
      check "No unscoped .find() in controllers" "PASS"
    else
      check "Unscoped .find() — use find_visible_incident! or scoped query" "FAIL" "$HITS"
    fi
  fi

  # Check: No .permit! (mass assignment vulnerability)
  HITS=$(echo "$RB_FILES" | xargs grep -n '\.permit!' 2>/dev/null || true)
  if [ -z "$HITS" ]; then
    check "No .permit! (mass assignment)" "PASS"
  else
    check ".permit! found — whitelist attributes explicitly" "FAIL" "$HITS"
  fi

  # Check: No direct status updates (should use StatusTransitionService)
  HITS=$(echo "$RB_FILES" | xargs grep -n 'update.*status:\|\.status\s*=' 2>/dev/null | grep -v 'StatusTransitionService\|test/' || true)
  if [ -z "$HITS" ]; then
    check "No direct status updates" "PASS"
  else
    check "Direct status update — use StatusTransitionService" "FAIL" "$HITS"
  fi

  echo ""
fi

# ─── Manual review reminders ─────────────────────────────
echo "─── Manual Review (Claude must verify) ───────────────"
echo ""
echo "  □ Server sends display-ready data (labels, not raw enums)"
echo "  □ TypeScript types match actual controller props"
echo "  □ No business logic in controllers (use services)"
echo "  □ Tests cover authorization scoping (cross-org isolation)"
echo "  □ Docs updated if schema or features changed"
echo ""

# ─── Summary ─────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════"
if [ "$FAILURES" -gt 0 ]; then
  echo " RESULT: ❌ $FAILURES FAIL / $PASSES PASS"
  echo ""
  echo " FIX ALL FAILURES BEFORE MOVING TO THE NEXT TASK."
  echo " Read the failing files line-by-line and fix each issue."
  echo "═══════════════════════════════════════════════════════"
else
  echo " RESULT: ✅ ALL $PASSES AUTOMATED CHECKS PASSED"
  echo ""
  echo " Still verify the manual review items above."
  echo "═══════════════════════════════════════════════════════"
fi

exit 0
