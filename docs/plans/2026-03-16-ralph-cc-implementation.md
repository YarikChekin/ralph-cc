# ralph-cc Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the ralph-cc Claude Code plugin — 11 skills, 1 agent, templates, and repo scaffolding — generalized from the closetize-app workflow.

**Architecture:** A Claude Code plugin distributed via GitHub. Skills are markdown files read by Claude Code at runtime. Templates are scaffolded into user projects by the `/init` skill. All project-specific references are replaced with `RALPH.md` lookups.

**Tech Stack:** Markdown (skills/agents/templates), JSON (plugin manifests, package.json, prd.json format), MIT License

**Source material:** All skills are generalized from `/Users/yarikchekin/Developer/closetize-app/.claude/skills/` and `/Users/yarikchekin/Developer/closetize-app/scripts/ralph/`. The design spec is at `/Users/yarikchekin/Developer/ralph-cc/docs/2026-03-16-ralph-cc-design.md`.

**Skill creation process:** Use the `skill-creator:skill-creator` skill when writing each SKILL.md file. This ensures skills follow Claude Code best practices for triggering, structure, and description quality. For each skill:
1. Read the corresponding closetize source skill first — borrow the structure heavily since it works well in practice
2. Generalize by replacing project-specific references with RALPH.md lookups (see spec Section 9)
3. Use skill-creator to validate/optimize the description for accurate triggering
4. The closetize skills are the primary reference — the spec provides generalization rules but the closetize implementations define the actual behavior and edge case handling

---

## Chunk 1: Repo Scaffolding & Templates

### Task 1: Plugin manifests and repo config

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `.claude-plugin/marketplace.json`
- Create: `package.json`
- Create: `LICENSE`
- Create: `CHANGELOG.md`

- [ ] **Step 1: Create plugin.json**

```json
{
  "name": "ralph-cc",
  "description": "Spec-driven development workflow — sprint planning, session management, and idea pipeline for Claude Code",
  "version": "1.0.0",
  "author": { "name": "YarikChekin" }
}
```

- [ ] **Step 2: Create marketplace.json**

```json
{
  "name": "ralph-cc",
  "owner": { "name": "YarikChekin" },
  "plugins": [
    {
      "name": "ralph-cc",
      "source": ".",
      "description": "Spec-driven development workflow for Claude Code",
      "version": "1.0.0"
    }
  ]
}
```

- [ ] **Step 3: Create package.json**

Minimal npm package for discoverability. `name: "ralph-cc"`, `version: "1.0.0"`, `description`, `keywords: ["claude-code", "ralph", "workflow", "sprint", "agent"]`, `license: "MIT"`, `repository` pointing to GitHub.

- [ ] **Step 4: Create LICENSE**

MIT license. Copyright line: `Copyright (c) 2026 YarikChekin`. Include note that this is based on snarktank/ralph (MIT).

- [ ] **Step 5: Create CHANGELOG.md**

Initial entry: `## 1.0.0 — [date]` with "Initial release" and feature list.

- [ ] **Step 6: Commit**

```bash
git add .claude-plugin/ package.json LICENSE CHANGELOG.md
git commit -m "feat: add plugin manifests and repo config"
```

### Task 2: Template files

**Files:**
- Create: `templates/RALPH.md`
- Create: `templates/scripts/ralph/prompt.md`
- Create: `templates/scripts/ralph/prd.json.example`
- Create: `templates/docs/tech-debt.md`
- Create: `templates/docs/testing/issues.md`
- Create: `templates/docs/ideas/_index.md`

**Source:** Read these closetize files for reference:
- `/Users/yarikchekin/Developer/closetize-app/scripts/ralph/prompt.md` — generalize into `templates/scripts/ralph/prompt.md`
- `/Users/yarikchekin/Developer/closetize-app/scripts/ralph/prd.json` — use as basis for `prd.json.example`

- [ ] **Step 1: Create templates/RALPH.md**

The project-level config template. Use the exact format from spec Section 4, with placeholder values (`[Project name]`, `[e.g., npm run typecheck]`, etc.). This file is what `/init` writes after asking setup questions.

- [ ] **Step 2: Create templates/scripts/ralph/prompt.md**

Read `/Users/yarikchekin/Developer/closetize-app/scripts/ralph/prompt.md` first — use it as the base and adapt. Generalize with these changes:
- Remove all closetize-specific references (Maestro, Expo, Supabase, design tokens)
- Replace hardcoded `npm run typecheck` with "Run quality checks from RALPH.md"
- Replace hardcoded commit format with "Use commit format from RALPH.md Git section"
- Keep: codebase exploration section (read closest completed feature, shared components, hooks, DB schema)
- Keep: progress report format (append-only, learnings section)
- Keep: consolidate patterns section
- Keep: update AGENTS.md section
- Keep: stop condition (one story per iteration)
- Keep: tech debt handling rules
- Add: "Read RALPH.md first to understand project config, quality commands, and document paths"
- Make E2E/testFlow conditional: "If the story has a `testFlow` and RALPH.md has `e2e_single` configured, run: [e2e_single command with flow path]"

- [ ] **Step 3: Create templates/scripts/ralph/prd.json.example**

Use the example from the spec Section 7. Shows the expected JSON structure with `project`, `source`, `sourceItem`, `branchName`, `description`, `userStories` array.

- [ ] **Step 4: Create templates/docs/tech-debt.md**

Template with two sections:

```markdown
# Tech Debt

## Active Items

| ID | Origin | Severity | Effort | Description | Files |
|----|--------|----------|--------|-------------|-------|

## Resolved Items

| ID | Origin | Severity | Effort | Description | Resolution |
|----|--------|----------|--------|-------------|------------|
```

- [ ] **Step 5: Create templates/docs/testing/issues.md**

```markdown
# Testing Issues

| # | Severity | Feature | Description | Status |
|---|----------|---------|-------------|--------|

## Severity Levels
- **Blocker**: Can't continue testing or core feature broken
- **Major**: Feature broken, workaround exists. Fix before launch.
- **Minor**: Cosmetic or UX. Fix when convenient.
- **Polish**: Nice-to-have improvement. Backlog.

## Status Values
- **Logged**: Found, not yet addressed
- **Fixed**: Fixed and verified (include commit hash)
- **Deferred**: Intentionally postponed (include reason)
- **Won't Fix**: Decided not to fix (include reason)
```

- [ ] **Step 6: Create templates/docs/ideas/_index.md**

```markdown
# Ideas

Living index of product ideas. Use `/new-idea` to add new entries.

| Idea | Status | Effort | Value | File |
|------|--------|--------|-------|------|
```

- [ ] **Step 7: Commit**

```bash
git add templates/
git commit -m "feat: add project templates for /init scaffolding"
```

---

## Chunk 2: Core Workflow Skills (init, start, ralph, wrap)

### Task 3: /init skill

**Files:**
- Create: `skills/init/SKILL.md`

**Source:** No direct closetize equivalent — this is new. Spec Section 5.1.

- [ ] **Step 1: Write skills/init/SKILL.md**

Frontmatter: `name: init`, `description: Scaffold ralph-cc into a project — creates RALPH.md, scripts/ralph/, and doc templates`.

Skill body implements the flow from spec Section 5.1:
1. Check for existing RALPH.md
2. Scaffold directory structure (copy templates)
3. Ask setup questions (project name, typecheck/lint/test commands, E2E setup)
4. Write RALPH.md with answers
5. Append ralph section to CLAUDE.md if it exists
6. Show next steps

Key details:
- Scan `package.json` / `Makefile` / `pyproject.toml` / `Cargo.toml` for command hints
- Create `scripts/ralph/progress.txt` with initial structure (log header + empty Codebase Patterns section)
- Don't scaffold docs that already exist (check first)
- E2E testing rules paragraph from spec

- [ ] **Step 2: Commit**

```bash
git add skills/init/
git commit -m "feat: add /init skill for project scaffolding"
```

### Task 4: /start skill

**Files:**
- Create: `skills/start/SKILL.md`

**Source:** Generalize from `/Users/yarikchekin/Developer/closetize-app/.claude/skills/start/SKILL.md`. Spec Section 5.4.

- [ ] **Step 1: Read the closetize /start skill**

Read `/Users/yarikchekin/Developer/closetize-app/.claude/skills/start/SKILL.md` to understand the full structure.

- [ ] **Step 2: Write skills/start/SKILL.md**

Frontmatter: `name: start`, `description: Assess project state and pick up where the last session left off — the single entry point for any new session`, `disable-model-invocation: true`.

Generalize the closetize version:
- Add RALPH.md validation at top of Step 1 (check exists, has required fields)
- Replace `npm run typecheck` → read from RALPH.md Quality Commands
- Replace `scripts/ralph/test-plan.json` → read from RALPH.md Testing section
- Replace `docs/testing/issues.md` → read from RALPH.md Documents.issues
- Replace `docs/POST_MVP_IMPROVEMENTS.md` → read from RALPH.md Documents.backlog
- Remove closetize-specific Maestro references
- Remove closetize-specific version bump steps in Case D (replace with generic: "If your project uses versioning, bump version and tag per your conventions")
- Fix case numbering (E, F, G as defined in spec)
- Add WIP commit parsing rule
- Make E2E conditional on RALPH.md config
- In "Start Working" → "Load Context" section, reference RALPH.md Documents paths instead of hardcoded file names
- Keep the full case structure (A through G) and "Start Working" execution section

- [ ] **Step 3: Commit**

```bash
git add skills/start/
git commit -m "feat: add /start skill for session dispatch"
```

### Task 5: /ralph skill

**Files:**
- Create: `skills/ralph/SKILL.md`

**Source:** Generalize from `/Users/yarikchekin/Developer/closetize-app/.claude/skills/ralph/SKILL.md`. Spec Section 5.5.

- [ ] **Step 1: Write skills/ralph/SKILL.md**

Frontmatter: `name: ralph`, `description: Show current sprint status and generate the kickoff prompt for a new agent session`, `disable-model-invocation: true`.

Generalize:
- Remove hardcoded project path from kickoff prompt — use `[project root]` placeholder or detect from current working directory
- Remove closetize-specific file references in the kickoff prompt — reference RALPH.md and let the agent discover paths from there
- Keep the dashboard table format
- Keep the kickoff prompt structure but generalize file list:
  1. `scripts/ralph/prompt.md`
  2. `scripts/ralph/prd.json`
  3. `scripts/ralph/progress.txt` (Codebase Patterns section)
  4. `RALPH.md` (project config, quality commands, doc paths)
  5. `CLAUDE.md` (if exists — project overview)
  6. `AGENTS.md` (if exists — codebase conventions)
  7. Design doc from RALPH.md (if configured)
  8. E2E test reference (if configured and story has testFlow)

- [ ] **Step 2: Commit**

```bash
git add skills/ralph/
git commit -m "feat: add /ralph skill for sprint dashboard"
```

### Task 6: /wrap skill

**Files:**
- Create: `skills/wrap/SKILL.md`

**Source:** Generalize from `/Users/yarikchekin/Developer/closetize-app/.claude/skills/wrap/SKILL.md`. Spec Section 5.6.

- [ ] **Step 1: Read the closetize /wrap skill**

Read `/Users/yarikchekin/Developer/closetize-app/.claude/skills/wrap/SKILL.md` to understand the full structure.

- [ ] **Step 2: Write skills/wrap/SKILL.md**

Frontmatter: `name: wrap`, `description: Clean handoff when ending a session — commits WIP, logs progress, and summarizes for the next agent`, `disable-model-invocation: true`.

Generalize:
- Replace `npm run typecheck` → read from RALPH.md Quality Commands
- Replace hardcoded test-plan.json path → read from RALPH.md Testing section
- Replace hardcoded progress file paths → read from RALPH.md
- Remove closetize-specific references
- Keep dual workflow detection (dev sprint vs testing)
- Keep WIP commit format: `wip: [STORY-ID] - [description]` for dev, `wip: testing - [TC-ID] - [description]` for testing
- Keep handoff log formats for both workflows
- Keep the "ALWAYS commit before wrapping" rule

- [ ] **Step 3: Commit**

```bash
git add skills/wrap/
git commit -m "feat: add /wrap skill for session handoff"
```

---

## Chunk 3: Planning Skills (prd-plan, new-sprint)

### Task 7: /prd-plan skill

**Files:**
- Create: `skills/prd-plan/SKILL.md`

**Source:** New skill (no direct closetize equivalent). Based on spec Section 5.2, with inspiration from snarktank/ralph's `/prd` skill at `/Users/yarikchekin/Developer/ralph/skills/prd/SKILL.md`.

- [ ] **Step 1: Read snarktank's /prd skill**

Read `/Users/yarikchekin/Developer/ralph/skills/prd/SKILL.md`. Borrow: the lettered-option question format ("1A, 2C, 3B" quick answers), the PRD section structure (intro, goals, user stories, functional requirements, non-goals), and the "Writing for junior developers" guidance. Do NOT copy the content verbatim — adapt it into our 3-path flow.

- [ ] **Step 2: Write skills/prd-plan/SKILL.md**

Frontmatter: `name: prd-plan`, `description: Create or audit a Product Requirements Document — the master plan that all sprints trace back to. Required before any sprint can be generated.`

Structure:
- Gate: check RALPH.md exists
- First question: "What are you planning?" (3 paths)
- Path 1 (new product): deep walkthrough — vision, users, features, scope, data model, tech stack, success criteria. One question at a time. Prefer multiple choice where possible.
- Path 2 (new feature): lighter — scan codebase, read CLAUDE.md/AGENTS.md/README, then ask about the feature, scope, technical approach, dependencies
- Path 3 (audit): read existing PRD, check completeness against checklist (vision, personas, features with detail, non-goals, data model, priorities), walk through gaps one by one, rewrite into standard format
- Output format: standardized `docs/PRD.md` with sections (Overview/Vision, Target Users, Features with numbered subsections, Data Model, Tech Stack, Non-Goals, Open Questions)
- Update RALPH.md Documents.prd path after writing
- Include the PRD example from snarktank's skill as a reference (adapted to our format)
- Include "Writing for junior developers" guidance from snarktank: explicit, unambiguous, no jargon

- [ ] **Step 3: Commit**

```bash
git add skills/prd-plan/
git commit -m "feat: add /prd-plan skill for product requirements planning"
```

### Task 8: /new-sprint skill

**Files:**
- Create: `skills/new-sprint/SKILL.md`

**Source:** Generalize from `/Users/yarikchekin/Developer/closetize-app/.claude/skills/new-prd/SKILL.md`. Spec Section 5.3. Also reference snarktank/ralph's converter skill at `/Users/yarikchekin/Developer/ralph/skills/ralph/SKILL.md` for story sizing rules.

- [ ] **Step 1: Read both source skills**

Read closetize `/new-prd` and snarktank `/ralph` converter skill.

- [ ] **Step 2: Write skills/new-sprint/SKILL.md**

Frontmatter: `name: new-sprint`, `description: Generate the next sprint from the PRD, backlog, or tech debt — detects completed features, picks the next chunk of work, and builds stories with minimal user input`.

Generalize:
- Gate: PRD must exist (check RALPH.md Documents.prd). If not, refuse and point to `/prd-plan`.
- Read all paths from RALPH.md (PRD, backlog, tech debt, ideas)
- Replace closetize PRD section references (4.1-4.7) with generic feature detection — parse the PRD's feature sections dynamically
- Priority order for next work (from spec): v1/MVP incomplete → high-priority backlog → high-severity tech debt → other backlog → user choice
- Archive rules from spec (warn if incomplete, derive feature name from branchName, handle directory collisions)
- Story generation rules from closetize version + snarktank story sizing rules:
  - Dependency order (schema → backend → UI → integration)
  - Each story fits one context window
  - Verifiable acceptance criteria
  - Quality command from RALPH.md in every story
  - testFlow only if E2E configured
  - 5-8 stories per sprint
  - Story notes reference existing patterns and file paths
- prd.json metadata (source, sourceItem)
- Include source-specific story generation guidance (from PRD section, from backlog item, from tech debt item)
- Keep the review-with-user step before writing

- [ ] **Step 3: Commit**

```bash
git add skills/new-sprint/
git commit -m "feat: add /new-sprint skill for sprint generation"
```

---

## Chunk 4: Side Workflow Skills (log, new-idea, promote-idea, tech-debt-review, test)

### Task 9: /log skill

**Files:**
- Create: `skills/log/SKILL.md`

**Source:** Generalize from `/Users/yarikchekin/Developer/closetize-app/.claude/skills/log/SKILL.md`. Spec Section 5.7.

- [ ] **Step 1: Write skills/log/SKILL.md**

Frontmatter: `name: log`, `description: Quick-capture bugs or improvement ideas mid-session without losing focus on current work`.

Generalize:
- Read file paths from RALPH.md Documents section (issues path, backlog path)
- Remove closetize-specific feature references
- Keep: input parsing (bug vs improvement), clarifying questions, routing logic, severity classification, "fix now vs later" recommendation
- Add: create target files from templates if they don't exist
- Keep: duplicate detection, format matching, "don't investigate" rule

- [ ] **Step 2: Commit**

```bash
git add skills/log/
git commit -m "feat: add /log skill for quick bug/improvement capture"
```

### Task 10: /new-idea skill

**Files:**
- Create: `skills/new-idea/SKILL.md`

**Source:** Generalize from `/Users/yarikchekin/Developer/closetize-app/.claude/skills/new-idea/SKILL.md`. Spec Section 5.8.

- [ ] **Step 1: Write skills/new-idea/SKILL.md**

Frontmatter: `name: new-idea`, `description: Brainstorm, research, and document feature ideas — structured capture that ports directly into sprint planning`.

Generalize:
- Read project context from RALPH.md and PRD (not closetize-specific docs)
- Remove closetize persona references ("See docs/PRODUCT_REQUIREMENTS_DOCUMENT.md section 3 for Closetize personas") → "See your PRD for user personas"
- Market research uses generic framing (not fashion-specific)
- Codebase audit reads CLAUDE.md/AGENTS.md/README generically
- Keep: idea exploration flow, market research structure, codebase audit, assessment dimensions, documentation template, status values, index update, promote-or-save-for-later offer
- Keep: ideas directory path as `docs/ideas/` (standard)

- [ ] **Step 2: Commit**

```bash
git add skills/new-idea/
git commit -m "feat: add /new-idea skill for idea brainstorming"
```

### Task 11: /promote-idea skill

**Files:**
- Create: `skills/promote-idea/SKILL.md`

**Source:** Generalize from `/Users/yarikchekin/Developer/closetize-app/.claude/skills/promote-idea/SKILL.md`. Spec Section 5.9.

- [ ] **Step 1: Write skills/promote-idea/SKILL.md**

Frontmatter: `name: promote-idea`, `description: Move a researched idea from docs/ideas/ into the backlog for sprint planning — resolves open questions and finalizes the approach`.

Generalize:
- Read backlog path from RALPH.md Documents.backlog
- Remove closetize-specific format references
- Keep: show all ideas sorted by readiness, pick one, walk through open questions, write backlog entry, update idea status
- Keep: format rules (Decided Approach not Proposed Solution, no effort/value/market research in backlog entry)

- [ ] **Step 2: Commit**

```bash
git add skills/promote-idea/
git commit -m "feat: add /promote-idea skill for backlog promotion"
```

### Task 12: /tech-debt-review skill

**Files:**
- Create: `skills/tech-debt-review/SKILL.md`

**Source:** Generalize from `/Users/yarikchekin/Developer/closetize-app/.claude/skills/tech-debt-review/SKILL.md`. Spec Section 5.10.

- [ ] **Step 1: Write skills/tech-debt-review/SKILL.md**

Frontmatter: `name: tech-debt-review`, `description: Assess tech debt health — reads docs/tech-debt.md, evaluates severity and accumulation, recommends which items to address`.

Generalize:
- Read tech debt file path from RALPH.md Documents.tech_debt
- Add "Read RALPH.md first" instruction at top of process
- Replace any hardcoded `docs/tech-debt.md` paths with RALPH.md lookup
- Keep: process flow, assessment criteria, thresholds (>8 items, >3 high-severity, >3 sprints old), output format — these are already generic

- [ ] **Step 2: Commit**

```bash
git add skills/tech-debt-review/
git commit -m "feat: add /tech-debt-review skill"
```

### Task 13: /test skill

**Files:**
- Create: `skills/test/SKILL.md`

**Source:** Generalize from `/Users/yarikchekin/Developer/closetize-app/.claude/skills/test/SKILL.md`. Spec Section 5.11.

- [ ] **Step 1: Write skills/test/SKILL.md**

Frontmatter: `name: test`, `description: Guided manual testing loop — present test cases conversationally, record pass/fail results, log issues, fix blockers`.

Generalize:
- Read test plan path from RALPH.md Testing section
- Read issues path from RALPH.md Documents.issues
- Remove closetize-specific references (Expo Go, Expo dev server, iOS simulator)
- Remove closetize-specific test preamble references
- Keep: full testing loop structure (load state, show dashboard, present tests conversationally, record results, severity classification, blocker handling, feature group pauses, session end, archival)
- Keep: test-plan.json structure (generalized device/method fields)
- Keep: issues.md format and status values
- Keep: "update after EACH test case" rule

- [ ] **Step 2: Commit**

```bash
git add skills/test/
git commit -m "feat: add /test skill for manual testing loop"
```

---

## Chunk 5: Agent & README

### Task 14: story-reviewer agent

**Files:**
- Create: `agents/story-reviewer.md`

**Source:** Generalize from `/Users/yarikchekin/Developer/closetize-app/.claude/agents/story-reviewer.md`. Spec Section 6.1.

- [ ] **Step 1: Write agents/story-reviewer.md**

Frontmatter: `name: story-reviewer`, `description: Reviews completed Ralph stories against acceptance criteria, project patterns, and code quality. Use after a story is marked as passing or before merging a sprint branch.`, `tools: Glob, Grep, LS, Read, Bash` (Glob/Grep for finding files and patterns, LS for directory listing, Read for file contents, Bash for git log/show/diff commands), `model: inherit`.

Generalize:
- Replace "You are a code reviewer for the Closetize app" → "You are a code reviewer for a ralph-cc managed project"
- Read patterns from CLAUDE.md / AGENTS.md (whatever exists in the project)
- Design principles check only if RALPH.md Documents.design is configured
- Remove closetize-specific pattern checks (Supabase, Expo Router, useAuth, theme tokens, etc.) → replace with "Check against patterns documented in CLAUDE.md and AGENTS.md"
- Quality commands from RALPH.md
- Keep: review process (gather context, check acceptance criteria, check design principles if configured, check codebase patterns, check common issues, check test flow if applicable)
- Keep: output format (criteria pass/fail, design check, pattern check, issues by severity, summary)
- Keep: "only flag real issues" and "read the actual file before flagging" rules

- [ ] **Step 2: Commit**

```bash
git add agents/
git commit -m "feat: add story-reviewer agent"
```

### Task 15: README.md

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write README.md**

Structure:
- Title + one-line description
- ASCII art banner or simple logo (optional — can add later)
- "What is ralph-cc?" — 2-3 paragraphs explaining the problem and solution
- Quick start:
  1. Plugin install (`/plugin marketplace add`, `/plugin install`)
  2. `/init` in your project
  3. `/prd-plan` to define requirements
  4. `/new-sprint` to create first sprint
  5. `/start` to begin working
- Manual install (clone + copy)
- Skills reference table (all 11 skills with one-line descriptions)
- Workflow diagram (from spec Section 8)
- Credits: "Based on [snarktank/ralph](https://github.com/snarktank/ralph) and [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/)"
- License: MIT

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "feat: add README with install guide and skill reference"
```

### Task 16: Initialize git repo and final commit

- [ ] **Step 1: Initialize git repo** (if not already — check with `git status` first)

```bash
cd /Users/yarikchekin/Developer/ralph-cc
git status 2>/dev/null || git init
```

- [ ] **Step 2: Create .gitignore** (in repo root)

```
node_modules/
.DS_Store
```

- [ ] **Step 3: Add all files and create initial commit**

Note: If individual commits were already made per task, this step is a verification that everything is committed. If working in a fresh repo, this is the initial commit with all files.

```bash
git add -A
git status
```

- [ ] **Step 4: Verify repo structure matches spec**

Run `find . -type f | grep -v '.git/' | sort` and compare against spec Section 3 directory layout. All files should be present.
