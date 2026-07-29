# Git Analysis

Repository: `C:\Users\Ziggy\Dropbox\GitHub\fuck_corpo`
Origin: `https://github.com/naperry2011/fuck_corpo.git`
Analysis date: 2026-07-28

---

## 1. Summary

| Metric | Value |
|---|---|
| Total commits (all refs) | 2 |
| Local branches | `main`, `zali-init` (checked out) |
| Remote branches | `origin/main`, `origin/HEAD` |
| Tags | 0 |
| Merge commits | 0 |
| HEAD | `34e0f62` |
| Tracked files | 52 |
| Contributors | 1 |

All three refs point at the same commit. `zali-init` is a working branch with no commits of its own yet.

---

## 2. Contributors

| Name | Email | Commits | First commit | Last commit |
|---|---|---|---|---|
| Perry | nuperry2011@gmail.com | 2 | 2026-02-05 20:11:30 -0700 | 2026-02-05 20:15:07 -0700 |

Single-author repository. The entire authoring window spans 3 minutes 37 seconds. The project was committed as a single large drop rather than developed incrementally in version control.

---

## 3. Commit cadence

### Monthly

| Month | Commits | Files changed | Insertions | Deletions |
|---|---|---|---|---|
| 2026-02 | 2 | 53 | 12,301 | 9 |

### Weekly (ISO)

| ISO week | Commits | Insertions | Deletions |
|---|---|---|---|
| 2026-W06 | 2 | 12,301 | 9 |

### Top single-day commit counts

| Date | Commits |
|---|---|
| 2026-02-05 | 2 |

### Line-change distribution

`package-lock.json` accounts for 6,893 of the 12,083 insertions in the initial commit, roughly 57 percent. Excluding the lockfile and the two specification documents, hand-written application source is approximately 4,600 lines. `image.png` is the only binary blob and is excluded from line counts.

Largest tracked files by line count:

| File | Lines |
|---|---|
| `package-lock.json` | 6,893 |
| `src/components/Application.css` | 655 |
| `fuckcorpo-design-system.md` | 648 |
| `src/components/Application.jsx` | 470 |
| `src/pages/Dashboard.css` | 445 |
| `src/pages/Dashboard.jsx` | 437 |
| `src/pages/Achievements.css` | 443 |

---

## 4. Commit message quality

The full history is two commits:

| SHA | Message | Classification |
|---|---|---|
| `18a7224` | `first commit` | Poor. Generic, no scope, no body, describes a 52-file 12k-line change. |
| `34e0f62` | `read me file` | Poor. Lowercase, non-imperative, no scope, no body. |

Neither message follows Conventional Commits or a subject-plus-body convention. Neither carries a body. Zero of two would pass a default `commitlint` configuration. There is no evidence of amending, squashing, or message rewriting.

Practical consequence: the history carries no information about how the code evolved. There is nothing meaningful to bisect and nothing useful to `git blame`.

---

## 5. Branching and rewrite evidence

- Branching model: effectively none. A linear two-commit trunk on `main`, with `zali-init` created locally at the same SHA.
- Merges: zero merge commits. `34e0f62` has a single parent.
- Force-push evidence: none detectable. The local reflog contains only the clone entry and the `zali-init` checkout, both dated 2026-07-28. Because this is a same-day fresh clone, the reflog cannot reveal any upstream history rewriting that occurred before the clone. Absence of evidence here is not evidence of absence.
- Dormancy: commits are dated 2026-02-05 while the clone occurred 2026-07-28, roughly 5.7 months with no upstream activity.

---

## 6. Repository size and large blobs

**VERIFICATION-GAP.** `git count-objects -vH` and the `git rev-list --objects --all | git cat-file --batch-check` pipeline were both blocked by the sandbox permission layer and returned no exit code from git. Repository size and a top-10 blob table could not be produced.

Substitute assessment: with two commits, no deleted history, and one tracked binary (`image.png`, 264,655 bytes on disk), packfile bloat is very unlikely. Re-run the two commands above with shell permission granted to close this gap.

---

## 7. Working tree and `.gitignore`

`git status --porcelain` returned five entries, all untracked, working tree otherwise clean:

```
?? .hermes/
?? CODE_MAP.md
?? DATA_FLOW.md
?? ENTRY_POINTS.md
?? IMPORT_GRAPH_SUMMARY.md
```

These are analysis artifacts from a prior tooling run, not application source. None are covered by `.gitignore`.

`.gitignore` is the stock Vite template, 24 lines, unmodified. It covers `node_modules`, `dist`, `dist-ssr`, `*.local`, log files, editor directories, and `.DS_Store`.

Gaps:

1. **No `.env` or `.env.*` rule.** This is the most material gap. A secrets file at the repository root would be committed silently. `*.local` catches `.env.local` only by coincidence of the Vite naming convention; a plain `.env` is unignored. There is no `.env` file today and the application reads no environment variables, so this is preventive rather than remedial.
2. No rule for `.hermes/` or other tool output, which is why five artifacts show as noise in `git status`.
3. No `coverage/`, `.cache/`, `*.tsbuildinfo`, or `Thumbs.db` (relevant on a Windows host).
4. `node_modules` and `dist` are unanchored patterns rather than `node_modules/` and `dist/`. Functionally equivalent here.

---

## 8. Build artifacts in version control

**None.** `git ls-files` returns 52 entries with no `node_modules/`, `dist/`, or `build/` paths and no minified bundles. The only generated file tracked is `package-lock.json`, which is correct and intentional.

---

## 9. Hygiene scorecard

| Dimension | Rating | Note |
|---|---|---|
| No vendored dependencies | Good | Clean `git ls-files` |
| No build output committed | Good | Verified |
| Lockfile committed | Good | `package-lock.json` present, lockfileVersion 3 |
| Source layout | Good | Conventional React tree |
| Working tree clean | Good | Only untracked tool artifacts |
| Commit message quality | Poor | 0/2 messages informative |
| Commit granularity | Poor | Entire project in one drop |
| Branch protection and PR flow | Absent | No CI, no protected branches observed |
| Tags and releases | Absent | Zero tags |
| `.gitignore` completeness | Fair | Missing `.env*` |

The structural hygiene is sound. The weaknesses are process-level. The two highest-value changes before the history grows are adding `.env*` and `.hermes/` to `.gitignore`, and adopting a commit message convention.

---
generated_by: codebase-audit skill v1.1
generated_on: 2026-07-28
project: C:\Users\Ziggy\Dropbox\GitHub\fuck_corpo
project_type: node
verification: full
---
