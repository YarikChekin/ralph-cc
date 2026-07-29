# RALPH.md

## Project
Name: [Project name]
Description: [One-line description]
Type: [product | feature]

## Quality Commands
typecheck: [e.g., npm run typecheck]
lint: [e.g., npm run lint]
test: [e.g., npm test]
e2e: [optional — e.g., npm run test:e2e]
e2e_single: [optional — e.g., bash scripts/test-e2e.sh {flow}]

## Documents
prd: docs/PRD.md
backlog: docs/POST_MVP_IMPROVEMENTS.md
design: [optional — e.g., docs/DESIGN_PRINCIPLES.md]
tech_debt: docs/tech-debt.md
issues: docs/testing/issues.md
ideas: docs/ideas/_index.md

## Testing (optional — only if using /test for manual testing)
test_plan: scripts/ralph/test-plan.json
test_progress: scripts/ralph/test-progress.txt

## Audit (optional — defaults: mode=sprint-close, reports_dir=scripts/ralph/audit-reports, team_name=ralph-<project folder>, model=sonnet)
mode: sprint-close          # off | sprint-close | per-story
reports_dir: scripts/ralph/audit-reports
model: sonnet               # tier name (sonnet | opus | haiku) passed as the Agent-tool model override at spawn — tier names track the newest model in that tier, so this never goes stale; a full model ID also works if you want to pin an exact version
team_name: ralph-my-project # unique per project. Current Claude Code ignores it (teams are per-session); older versions key teams by name MACHINE-GLOBALLY, where a shared name cross-wires concurrent projects — keep it unique for back-compat. Spawned agents use a project-suffixed name too (auditor-<project folder>).

## Merge (optional — defaults: mode=local, branch_base=main)
mode: local                  # local | pr
branch_base: main

## Reviewers (optional — defaults: enabled=false; only used when Merge.mode=pr)
enabled: false               # if true, /start's PR flow dispatches Code Reviewer + QA Engineer (scripts/ralph/pr-review.sh) and merge waits for both APPROVE verdicts

## Recap (optional — defaults: enabled=ask, evidence_dir=scripts/ralph/evidence)
enabled: ask                 # off | ask | on — visual "what shipped" artifact at sprint close
evidence_dir: scripts/ralph/evidence  # per-story screenshot dirs (<evidence_dir>/<story-id>/) used when present

## SprintPlan (optional — defaults: artifact=off)
artifact: off                # off | ask | on — visual sprint-plan page when /new-sprint finishes (scope at a glance before work starts)

## Github (optional — defaults: enabled=false)
enabled: false               # if true, /start surfaces gh issues, /new-sprint accepts issue sources

## Git
commit_format: feat: [{story_id}] - [{title}]
branch_prefix: ralph/
