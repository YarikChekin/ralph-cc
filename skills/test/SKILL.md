---
name: test
description: Use when the user wants to run manual tests on a device or in a browser, continue an in-progress test round, or review testing issues
---

# /test — Manual Testing Loop

Guide the user through manual test cases on their device or environment. You present each test conversationally, the user runs it and reports back, you record the result.

## Before Starting

Read `RALPH.md` to find:
- `Testing.test_plan` — path to the test plan JSON file
- `Testing.test_progress` — path to the test progress file
- `Documents.issues` — path to the issues file

If `RALPH.md` doesn't exist or is missing the Testing paths, tell the user: "RALPH.md is missing Testing configuration. Run `/ralph-init` to set up your project, or add the Testing section to RALPH.md manually."

## Step 1: Load State

Read silently before saying anything:

1. The test plan file (from RALPH.md `Testing.test_plan`) — test cases with pass/fail state
2. The test progress file (from RALPH.md `Testing.test_progress`) — previous session notes (if exists)
3. The issues file (from RALPH.md `Documents.issues`) — open issues (if exists)
4. `CLAUDE.md` — project context (if exists)

If the test plan file doesn't exist, tell the user: "No test plan found. Use `/new-sprint` or create the test plan file at [path from RALPH.md] first."

**Branch check**: Verify you're on the branch specified by `branchName` in the test plan. If not, check it out. If it doesn't exist, create it from main: `git checkout -b [branchName]`.

## Step 2: Show Dashboard

```
## Testing Session

Test Plan: [name]
Device: [device]
Progress: [passed]/[total] passed, [failed] failed, [remaining] remaining
Open Issues: [count] ([blockers] blockers, [majors] major)

Next up: [next test case ID] — [title]
```

Ask: "Ready to continue testing, or would you rather review open issues first?"

## Step 3: Run the Testing Loop

For each test case where `passes` is `null`:

### Present the Test

Tell the user what to do conversationally. Include:
- The test ID and title
- Step-by-step instructions (from the `steps` array)
- What they should expect to see (from `expected`)

Example: *"Next up: TC-04 — Add Item via Upload. Open the main screen, tap the + button, choose 'Upload'. Select an image. You should see a loading indicator, then a pre-filled form. What happened?"*

### Record the Result

Based on user feedback:

**PASS**: Update the test plan file — set `passes: true`, update `current` to the next test case ID. Say "TC-XX passes" and move to the next test.

**FAIL**: Ask clarifying questions if needed (what exactly happened, any error messages, screenshots). Then:

1. Classify severity:
   - **Blocker**: Can't continue testing or core feature completely broken
   - **Major**: Feature broken but can work around it. Must fix before launch.
   - **Minor**: Cosmetic or UX issue. Fix when convenient.
   - **Polish**: "Nice to have" improvement. Backlog.

2. Update the test plan file — set `passes: false`, add description to `notes`, update `current` to the next test case ID

3. Add entry to the issues file (from RALPH.md `Documents.issues`):
   ```
   | [next #] | [Severity] | [Feature] | [Description] | Logged |
   ```

   If the issues file doesn't exist, create it from the template:

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

4. **If Blocker**: Stop testing. Investigate and fix the code. After fix, have the user reload the app and re-test. Update `passes` to `true` if fixed, update issue status to `Fixed`.

5. **If not Blocker**: Log it and continue to the next test case.

### After Each Feature Group

When all test cases sharing the same `feature` value are done (e.g., all test cases with `"feature": "Auth"`), pause and show:

```
## Auth — Complete

Passed: 3/4
Issues found: 1 (minor)

Moving to: Onboarding
```

## Step 4: Session End

When the user wants to stop or all tests are done:

1. Update the test plan file with final state
2. Write session entry to the test progress file (from RALPH.md `Testing.test_progress`):
   ```
   ## [DATE] - Testing Session
   - **Device**: [device]
   - **Tests run**: TC-XX through TC-YY
   - **Results**: [passed] passed, [failed] failed, [skipped] remaining
   - **Blockers fixed**: [list or "none"]
   - **Issues logged**: [count]
   - **Next up**: TC-ZZ — [title]
   ```
3. Show final dashboard with updated progress

### When All Tests Pass

Show completion summary:

```
## Test Round Complete!

All [total] test cases passed.
Issues logged: [count] ([breakdown by severity])
Blockers fixed during testing: [count]
```

Ask: "Want to review open issues, or archive this test round?"

**To archive**: Move the test plan file to `scripts/ralph/archive/[DATE]-[name]/test-plan.json` and the test progress file to the same archive directory.

## test-plan.json Structure

```json
{
  "name": "MVP Manual Testing",
  "branchName": "testing/mvp-round-1",
  "device": "Chrome 120, macOS",
  "method": "local dev server",
  "current": "TC-01",
  "testCases": [
    {
      "id": "TC-01",
      "title": "Fresh Signup",
      "feature": "Auth",
      "prdSection": "3.1",
      "precondition": "No existing account",
      "steps": [
        "Open the app — should see login screen",
        "Click 'Sign Up' link",
        "Enter name, email, password",
        "Click sign up button"
      ],
      "expected": "Account created, redirected to dashboard",
      "passes": null,
      "notes": ""
    }
  ]
}
```

- `passes: null` — not yet tested
- `passes: true` — passed
- `passes: false` — failed (details in `notes` and issues file)
- `current` — ID of the next test to run (update after each test)
- `device` — whatever the user is testing on (phone model, browser, etc.)
- `method` — how the app is being run (dev server, staging deploy, production, etc.)

## Key Behaviors

- **Be conversational**: You're guiding the user through tests, not reading a script. Adapt based on what they report.
- **Ask follow-up questions on failures**: "Did you see an error message?", "Was the button grayed out or just unresponsive?", "Can you scroll down — is the content maybe hidden?"
- **Track state persistently**: Always update the test plan file and issues file after each test. This is how sessions resume.
- **Don't batch updates**: Update the test plan and issues after EACH test case, not at the end. Sessions can be interrupted at any time.
- **Feature group pauses**: After completing all tests in a feature group, briefly summarize before moving on. This gives natural break points.
- **Re-testing failures**: When resuming a session, check for test cases with `passes: false`. If the underlying issue has been fixed (check issues file status), re-run those tests first before continuing with untested cases.
