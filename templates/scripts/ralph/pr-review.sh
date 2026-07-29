#!/bin/bash
# pr-review — Run Code Reviewer + QA Engineer on a PR in parallel
#
# Usage:
#   bash scripts/ralph/pr-review.sh          # auto-detects PR from current branch
#   bash scripts/ralph/pr-review.sh 55       # review PR #55
#   bash scripts/ralph/pr-review.sh 55 code  # run only Code Reviewer
#   bash scripts/ralph/pr-review.sh 55 qa    # run only QA Engineer
#
# Both agents run as separate Claude Code CLI processes (parallel, independent
# context windows), resolved from this project's .claude/agents/ definitions
# (code-reviewer.md + qa-engineer.md, scaffolded by /ralph-init). Each posts
# its findings as a GitHub PR comment ending in an APPROVE / REQUEST CHANGES
# verdict.
#
# Each agent writes its review draft to a script-scoped tmp dir (auto-cleaned
# on script exit) before posting via `gh pr comment --body-file`. No scratch
# files linger in the working tree.
#
# Re-review: just run again after pushing fixes. The agents read their own
# prior comments and check whether previous feedback was addressed.
#
# If the script reports "N agent(s) failed": check WHICH review actually
# posted (`gh pr view <N> --comments`) before re-dispatching — an agent can
# fail after posting (double-post) or fail without posting (missing review).
# Re-run just the missing one with the `code` / `qa` filter.

set -euo pipefail

# --- Resolve PR number ---
PR_NUMBER="${1:-}"
if [ -z "$PR_NUMBER" ]; then
  PR_NUMBER=$(gh pr view --json number -q .number 2>/dev/null || true)
fi

if [ -z "$PR_NUMBER" ]; then
  echo "Error: No PR found for the current branch."
  echo "Usage: bash scripts/ralph/pr-review.sh <PR_NUMBER> [code|qa]"
  exit 1
fi

AGENT_FILTER="${2:-all}"

# --- Verify PR exists ---
PR_TITLE=$(gh pr view "$PR_NUMBER" --json title -q .title 2>/dev/null || true)
if [ -z "$PR_TITLE" ]; then
  echo "Error: PR #$PR_NUMBER not found."
  exit 1
fi

# --- Set up script-scoped temp dir for review drafts ---
# Each agent writes its draft markdown here, then pipes it to `gh pr comment
# --body-file`. The trap auto-cleans on any exit (success or failure) so no
# scratch files end up in the repo working tree.
TMP_DRAFT_DIR=$(mktemp -d -t "pr-review-${PR_NUMBER}-XXXXXX")
trap "rm -rf '$TMP_DRAFT_DIR'" EXIT

echo "╔══════════════════════════════════════════════════╗"
echo "║  PR Review — #$PR_NUMBER"
echo "║  $PR_TITLE"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# --- Build the review prompt ---
# The agents' instruction files (.claude/agents/*.md) define HOW to review.
# This prompt tells them WHAT to review and handles re-review context.
# Step 7 (draft path) is appended per-agent below so each gets a unique file.
REVIEW_PROMPT_BASE="Review PR #$PR_NUMBER.

Steps:
1. Run: gh pr diff $PR_NUMBER
2. Run: gh pr view $PR_NUMBER --json title,body,files
3. Run: gh api repos/{owner}/{repo}/pulls/$PR_NUMBER/comments --paginate
   AND: gh pr view $PR_NUMBER --comments
   to check for any prior review comments.
4. If you find prior review comments from a Code Review or QA Review:
   - This is a RE-REVIEW. Read the prior feedback carefully.
   - Check the current diff to see if each prior issue was addressed.
   - In your new comment, reference prior issues: 'Previously flagged X — RESOLVED' or 'Previously flagged X — STILL PRESENT'.
   - Also flag any NEW issues introduced by the fixes."

# --- Launch agents ---
PIDS=()

if [ "$AGENT_FILTER" = "all" ] || [ "$AGENT_FILTER" = "code" ]; then
  echo "→ Starting Code Reviewer..."
  CODE_DRAFT="$TMP_DRAFT_DIR/code-review.md"
  CODE_PROMPT="$REVIEW_PROMPT_BASE
5. Read the project files specified in your instruction file for context.
6. Complete your full review checklist.
7. Post your review as a PR comment: write your full review markdown to '$CODE_DRAFT' first, then run \`gh pr comment $PR_NUMBER --body-file '$CODE_DRAFT'\`. Writing to a file first avoids shell escaping issues with the long markdown body. The file path is provided by the launcher; do not write reviews to the repo working tree."
  claude --agent code-reviewer -p "$CODE_PROMPT" > /dev/null 2>&1 &
  PIDS+=($!)
fi

if [ "$AGENT_FILTER" = "all" ] || [ "$AGENT_FILTER" = "qa" ]; then
  echo "→ Starting QA Engineer..."
  QA_DRAFT="$TMP_DRAFT_DIR/qa-review.md"
  QA_PROMPT="$REVIEW_PROMPT_BASE
5. Read the project files specified in your instruction file for context.
6. Complete your full review checklist.
7. Post your review as a PR comment: write your full review markdown to '$QA_DRAFT' first, then run \`gh pr comment $PR_NUMBER --body-file '$QA_DRAFT'\`. Writing to a file first avoids shell escaping issues with the long markdown body. The file path is provided by the launcher; do not write reviews to the repo working tree."
  claude --agent qa-engineer -p "$QA_PROMPT" > /dev/null 2>&1 &
  PIDS+=($!)
fi

echo ""
echo "Agents running in parallel. Waiting for both to finish..."
echo "(Reviews will appear as comments on PR #$PR_NUMBER)"
echo "(Drafts in $TMP_DRAFT_DIR — auto-cleaned on exit)"
echo ""

# --- Wait for all agents ---
FAILED=0
for PID in "${PIDS[@]}"; do
  if ! wait "$PID"; then
    FAILED=$((FAILED + 1))
  fi
done

echo ""
if [ "$FAILED" -eq 0 ]; then
  echo "✓ All reviews posted. Check: gh pr view $PR_NUMBER --comments"
else
  echo "⚠ $FAILED agent(s) failed. Check which reviews actually posted:"
  echo "    gh pr view $PR_NUMBER --comments"
  echo "  A failed agent may still have posted (double-post) or not posted at all."
  echo "  Re-run only the missing one: bash scripts/ralph/pr-review.sh $PR_NUMBER code|qa"
fi
