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

## Git
commit_format: feat: [{story_id}] - [{title}]
branch_prefix: ralph/
