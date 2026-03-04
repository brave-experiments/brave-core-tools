---
name: check-best-practices
description: "Check local branch changes against all best practices documentation. Systematically audits the diff between current branch and base branch against every applicable best practice. Triggers on: check best practices, best practices check, audit best practices, bp check, check bp."
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(git merge-base:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(gh pr view:*), Bash(pwd:*), Read, Grep, Glob
---

# Best Practices Check

Systematically audit the current branch's changes against every applicable best practice. This produces a per-document report showing which practices were checked, which violations were found, and which practices are not applicable to the current changes.

---

## Step 1: Detect Working Directory

Determine the brave source directory:

```bash
CURRENT_DIR=$(pwd)
```

- **If within `src/brave`**: `BRAVE_SRC="."`, `CHROMIUM_SRC="../../"`
- **If within `brave-core-tools`**: `BRAVE_SRC="../src/brave"`, `CHROMIUM_SRC="../src"`
- **Otherwise**: Look for characteristic files to detect, or ask the user

---

## Step 2: Determine Base Branch

Detect the base branch in this order:

1. **Check for an existing PR**:
   ```bash
   CURRENT_BRANCH=$(git -C $BRAVE_SRC branch --show-current)
   PR_BASE=$(gh pr view "$CURRENT_BRANCH" --repo brave/brave-core \
     --json baseRefName --jq '.baseRefName' 2>/dev/null) || true
   ```

2. **Check the upstream tracking branch**:
   ```bash
   TRACKING=$(git -C $BRAVE_SRC rev-parse --abbrev-ref \
     "$CURRENT_BRANCH@{upstream}" 2>/dev/null) || true
   ```

3. **Fall back to `master`**

Report the detected base branch at the start.

---

## Step 3: Gather the Diff

```bash
MERGE_BASE=$(git -C $BRAVE_SRC merge-base HEAD $BASE_BRANCH)

# All committed changes on this branch since diverging from base
git -C $BRAVE_SRC diff $MERGE_BASE..HEAD

# Uncommitted changes (staged + unstaged)
git -C $BRAVE_SRC diff HEAD

# List of changed files
git -C $BRAVE_SRC diff --name-only $MERGE_BASE..HEAD
git -C $BRAVE_SRC diff --name-only HEAD
```

Combine committed + uncommitted changes into the full diff to audit.

---

## Step 4: Classify Changed Files

Categorize every changed file to determine which best practices documents apply:

| File Pattern | Category | Best Practices Doc |
|---|---|---|
| `*.cc`, `*.h`, `*.mm` | C++ code | `coding-standards.md`, `coding-standards-memory.md`, `coding-standards-apis.md` |
| `*_browsertest*`, `*_unittest*`, `*test*.cc` | C++ tests | `testing-async.md`, `testing-isolation.md` |
| `*browsertest*` with JS eval | JS in tests | `testing-javascript.md` |
| `*browsertest*` with navigation | Navigation tests | `testing-navigation.md` |
| `*.ts`, `*.tsx`, `*.js`, `*.jsx` | Front-end | `frontend.md` |
| `*.java`, `*.kt`, `android/` paths | Android | `android.md` |
| `*.swift`, `ios/` paths | iOS | `ios.md` |
| `BUILD.gn`, `*.gni`, `DEPS` | Build system | `build-system.md` |
| `chromium_src/**` | chromium_src overrides | `chromium-src-overrides.md` |
| `*.patch`, `patches/` paths | Patches | `patches.md` |
| `*/res/drawable/*`, `*/res/values/*`, `components/vector_icons/`, `*.icon`, `*.svg` | Nala/icons | `nala.md` |
| Architecture/service files | Architecture | `architecture.md` |
| `*.md`, comments, docs | Documentation | `documentation.md` |

A file can match multiple categories (e.g., a `_browsertest.cc` is both C++ and test code).

**Always include `coding-standards.md` if any C++ files are changed**, since it covers universal C++ rules.

---

## Step 5: Chunk Documents and Launch Subagents in Parallel

For each applicable best-practice document, run the chunking script to split it into groups of ~20 rules, then launch one **Agent subagent** (subagent_type: "general-purpose") per chunk. **Use multiple Agent tool calls in a single message** so they run in parallel. Pass the diff content (gathered in Step 3) directly in each subagent's prompt so they don't need to fetch it again.

### Step 5.1: Chunk Each Document

For each applicable document, run:
```bash
python3 ./brave-core-tools/.claude/skills/check-best-practices/chunk-best-practices.py \
  ./brave-core-tools/docs/best-practices/<doc>.md
```

This outputs JSON with one or more chunks per document. Each chunk contains:
- `doc`: the source document filename
- `chunk_index` / `total_chunks`: position within the document
- `rule_count`: number of `##` rules in this chunk
- `headings`: list of rule heading texts (for the audit trail)
- `content`: the full text to pass to the subagent (includes the doc header + the chunk's rules)

Small documents (<=20 rules) produce 1 chunk. Large documents are split evenly (e.g., 65 rules -> 3 chunks of 22+22+21). Launch one subagent per chunk.

### Step 5.2: Document Applicability Table

| Document | Condition |
|----------|-----------|
| `coding-standards.md` | has_cpp_files |
| `coding-standards-memory.md` | has_cpp_files |
| `coding-standards-apis.md` | has_cpp_files |
| `architecture.md` | Always |
| `documentation.md` | Always |
| `build-system.md` | has_build_files |
| `testing-async.md` | has_test_files |
| `testing-javascript.md` | has_test_files |
| `testing-navigation.md` | has_test_files |
| `testing-isolation.md` | has_test_files |
| `chromium-src-overrides.md` | has_chromium_src |
| `frontend.md` | has_frontend_files |
| `android.md` | has_android_files |
| `ios.md` | has_ios_files |
| `patches.md` | has_patch_files |
| `nala.md` | has_nala_files |

**Always launch at minimum:** architecture and documentation (apply to all changes).

**Skip documents entirely if no changed files fall into their category.** Report which documents were skipped and why.

### Step 5.3: Subagent Prompt

Each subagent prompt MUST include:

1. **The chunk content** — embed the `content` field from the chunking script output directly in the prompt. The subagent does NOT read any best practice files — all rules are provided inline:
   ````
   Here are the best practice rules to check:
   ```markdown
   <chunk content>
   ```
   ````
2. **The diff content** — include the full diff text (gathered once in Step 3) directly in the prompt. The subagent MUST NOT re-gather the diff — it is already provided:
   ````
   Here is the diff to audit:
   ```diff
   <DIFF content>
   ```
   ````
3. **The review rules**:
   - Only flag violations in ADDED lines (+ lines), not existing code
   - Also flag bugs introduced by the change (e.g., missing string separators, duplicate entries, code inside wrong `#if` guard)
   - **Check surrounding context before making claims.** When a violation involves dependencies, includes, or patterns, the subagent should read the full file context to verify the claim is accurate
   - Do not suggest renaming imported symbols defined outside the diff's changed files
   - Do NOT flag: existing code the diff isn't changing, template functions defined in headers, simple inline getters in headers, style preferences not in the documented best practices, include/import ordering
   - **Every claim must be verified in the provided best practices rules.** Do NOT make claims based on general knowledge. If the provided rules do not contain a rule about something, do NOT flag it as a violation
4. **The systematic audit requirement** (Step 5.4 below)
5. **Required output format** (Step 5.5 below)

### Step 5.4: Systematic Audit Requirement

**CRITICAL — this is what prevents the subagent from stopping after finding a few violations.**

The subagent MUST work through its chunk **heading by heading**, checking every `##` rule against the diff. It must output an audit trail listing EVERY `##` heading in the chunk with a verdict:

```
AUDIT:
PASS: Always Include What You Use (IWYU)
PASS: Use Positive Form for Booleans and Methods
N/A: Consistent Naming Across Layers
FAIL: Don't Use rapidjson
PASS: Use CHECK for Impossible Conditions
... (one entry per ## heading in the chunk)
```

Verdicts:
- **PASS**: Checked the diff — no violation found
- **N/A**: Rule doesn't apply to the types of changes in this diff
- **FAIL**: Violation found — must have a corresponding entry in VIOLATIONS

This forces the model to explicitly consider every rule rather than satisficing after a few findings.

### Step 5.5: Required Subagent Output Format

Each subagent MUST return this structured format:

```
DOCUMENT: <document name> (chunk <chunk_index+1>/<total_chunks>)

AUDIT:
PASS: <rule heading>
N/A: <rule heading>
FAIL: <rule heading>
... (one line per ## heading in the chunk)

VIOLATIONS:
- file: <path>, line: <line_number>, severity: <"high"|"medium"|"low">, rule: "<rule heading>", issue: <brief description>, fix: <what should be done instead>
- ...
NO_VIOLATIONS (if none found)

Severity guide:
- high: Correctness bugs, use-after-free, security issues, banned APIs, test reliability problems (e.g., RunUntilIdle)
- medium: Substantive best practice violations (wrong container type, missing error handling, architectural issues)
- low: Nits, style preferences, missing docs, naming suggestions, minor cleanup
```

---

## Step 6: Aggregate and Validate Subagent Results

After ALL chunk subagents return:

1. **Aggregate violations** from all chunk subagents into a single list, grouped by document
2. **Aggregate audit trails** — merge the per-chunk AUDIT lines back into per-document summaries
3. **Deep-dive validation** — before including each violation in the report, read the actual source file at and around the flagged line. Verify the claim is true in context. Drop false positives where the code is actually correct in its full context. This is NOT optional — subagents work only from the diff, which lacks surrounding context. **Deprecation claims require header verification:** if a violation claims an API is deprecated, read the actual header file that declares the API and confirm a deprecation notice exists. Do not rely on training data — APIs change across chromium upgrades and assumptions are frequently wrong.
4. **Sort violations by severity**: high -> medium -> low

---

## Step 7: Check the Quick Checklist

After the per-document audit, also check the quick checklist from `BEST-PRACTICES.md` if any async test code was changed:

- [ ] No `RunLoop::RunUntilIdle()` usage
- [ ] No `EvalJs()` or `ExecJs()` inside `RunUntil()` lambdas
- [ ] Using manual polling loops for JavaScript conditions
- [ ] Using `base::test::RunUntil()` only for C++ conditions
- [ ] Waiting for specific completion signals, not arbitrary timeouts
- [ ] Using isolated worlds (`ISOLATED_WORLD_ID_BRAVE_INTERNAL`) for test JS
- [ ] Per-resource expected values for HTTP request testing
- [ ] Large throttle windows for throttle behavior tests
- [ ] Proper observers for same-document navigation
- [ ] Testing public APIs, not implementation details
- [ ] Searched Chromium codebase for similar patterns
- [ ] Included Chromium code references in comments when following patterns
- [ ] Prefer event-driven JS (MutationObserver) over C++ polling for DOM changes

---

## Step 8: Generate Report

```markdown
# Best Practices Audit: <branch-name>

## Overview
- **Branch**: <branch-name>
- **Base branch**: <base-branch> (detection method: PR / tracking / default)
- **Files changed**: <count>
- **Documents audited**: <count> of 16
- **Documents skipped**: <count> (not applicable)

## Violations Found

### <violation-count> Violation(s)

For each violation:

#### [<doc-name>] <practice-title>
- **File**: `path/to/file.cc:<line>`
- **Practice**: <brief description of the practice>
- **Issue**: <what the code does wrong>
- **Fix**: <what should be done instead, with code example if helpful>

## Per-Document Results

### <doc-name> — <VIOLATIONS_FOUND | ALL_PASS | SKIPPED>

<If audited, list practices checked with their status:>
- PASS: <practice title> — <brief note on what was checked>
- VIOLATION: <practice title> — see Violations section
- N/A: <practice title>

<If skipped:>
Skipped — no <category> files in the diff.

## Summary

**Result**: <PASS (no violations) | FAIL (<N> violations found)>

<If violations found:>
<N> violation(s) across <M> best practices document(s). Fix the violations listed above before proceeding.

<If no violations:>
All applicable best practices checked. No violations found in the branch changes.
```

---

## Important Guidelines

### Accuracy Over Speed
- **Read changed files in full** — don't just rely on the diff. Context matters.
- **Don't flag false positives** — if unsure whether something is a violation, read more context. A false positive wastes developer time.
- **Only flag new/modified code** — pre-existing violations in untouched code are out of scope.
- **Only flag violations documented in the best practices.** Do not make claims based on general knowledge or assumptions. If the best practices docs don't contain a rule about something, don't flag it — even if you believe it to be true. Hallucinated rules (e.g., claiming an API is "deprecated" when no doc says so) erode trust.
- **Before each comment, verify your claims by reading relevant source code in `src/brave/` and `src/`.** Do not assert that an API is deprecated, a pattern is wrong, or a function should be replaced without first checking the actual codebase. Look at how the API/pattern is used elsewhere in the codebase, read header files and upstream Chromium code to confirm your understanding. Ground every comment in what the code actually says.

### Be Specific and Actionable
- Every violation must include file, line, and a concrete fix suggestion.
- Reference the specific best practice by its title from the document.
- Include code examples when the fix isn't obvious.

### Don't Over-Report
- **N/A practices don't need individual listings** in the summary unless verbose output is requested. Group them as a count.
- Focus the report on violations and notable passes.
- Keep the report scannable — developers should be able to find violations quickly.
