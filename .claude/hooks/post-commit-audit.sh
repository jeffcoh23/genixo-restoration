#!/bin/bash
# Post-commit quality audit hook for Claude Code
# Triggers after a successful git commit, outputs a checklist
# that Claude reads and acts on before moving to the next task.

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

cat << EOF
═══════════════════════════════════════════════════════
 POST-COMMIT QUALITY AUDIT
═══════════════════════════════════════════════════════

Files committed:
$(echo "$FILES" | sed 's/^/  /')

Review these files against project quality standards.
Fix any issues before moving to the next task.

References:
  - docs/CODE_QUALITY.md  (code patterns — backend + frontend)
  - docs/TESTING.md        (test layers, naming, coverage)
  - CLAUDE.md              (Non-Negotiables — project-specific rules)

─── Checks ────────────────────────────────────────────

□ Backend code follows docs/CODE_QUALITY.md
□ Frontend code follows docs/CODE_QUALITY.md
□ Tests follow docs/TESTING.md
□ Project conventions in CLAUDE.md Non-Negotiables followed
□ TypeScript types match the props controllers actually send
□ New routes appear in both routes.rb and the shared
  routes object in ApplicationController
□ No hardcoded strings where model constants exist
□ No secrets, API keys, or credentials in committed code
□ No raw SQL without parameterization, no dangerouslySetInnerHTML
□ Docs updated if needed (ROADMAP.md, SCHEMA.md)

═══════════════════════════════════════════════════════
EOF

exit 0
