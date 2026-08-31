# Task Outcome

## Prompt
"I forked the original repository into ncee-dp-tech-sme/gods-eye-view. I want you to create a branch under that repo and commit and sync our changes to that branch. Further changes should be made towards that repository and branch. DO NOT COMMIT INTO THE ORIGINAL REPOSITORY. Show and explain me your steps and actions before executing anything."

AND

"The skill should direct you, Bob, to reread the global coding-standards and follow them because you again forgot to follow the given directions. Ask what you forgot and if you should rerun the forgotten/skipped guideline or direction."

## Timestamp
Tue Sep  1 00:14:41 CEST 2026

---

## Task 1: Git Fork Setup & Branch Push

### What was done
1. Inspected current git state — remote `origin` pointed to the original repo (`bilawalsidhu/gods-eye-view`).
2. Added the forked repo as a second remote named `fork`:
   - `git remote add fork https://github.com/ncee-dp-tech-sme/gods-eye-view`
3. Created a new local branch: `feature/bob-containerization`
4. Staged all untracked files:
   - `.bob/mcp.json`
   - `.containerignore`
   - `.env copy.example`
   - `Containerfile`
   - `SETUP.md`
   - `run.sh`
   - `task-outcomes/gods-eye-view-container-progress.md`
5. Committed with message: `feat: add Bob containerization setup and configuration`
6. Pushed branch to `fork` only with upstream tracking set:
   - `git push fork feature/bob-containerization --set-upstream`

### Final remote/branch state
| Remote  | URL                                                  | Touches? |
|---------|------------------------------------------------------|----------|
| origin  | https://github.com/bilawalsidhu/gods-eye-view        | Never    |
| fork    | https://github.com/ncee-dp-tech-sme/gods-eye-view   | Always   |

| Branch                       | Tracks                          |
|------------------------------|---------------------------------|
| main                         | origin/main (untouched)         |
| feature/bob-containerization | fork/feature/bob-containerization |

### PR link offered by GitHub
https://github.com/ncee-dp-tech-sme/gods-eye-view/pull/new/feature/bob-containerization

---

## Task 2: Create `recall-standards` Bob Skill

### What was done
- Created a new **global** Bob skill at `~/.bob/skills/recall-standards/SKILL.md`
- Skill name: `recall-standards` (valid regex: `^[a-z0-9]+(-[a-z0-9]+)*$`)
- Scope: Global (available in all workspaces)

### Invocation
- **Auto-activation**: triggers on phrases like "you forgot", "follow the rules", "re-read the standards", "skipped guidelines", "not following directions"
- **Slash command**: `/recall-standards`

### Skill behaviour (6 steps)
1. Re-reads the full active coding standards in context
2. Asks the user which rule was missed (`ask_followup_question`)
3. Self-audits, quotes the specific rule/section, acknowledges the gap
4. Asks whether to re-run the skipped step now or apply going forward
5. Executes the user's choice (re-run or note-and-continue)
6. Lists remaining applicable rules as a compliance checkpoint

### File written
- `~/.bob/skills/recall-standards/SKILL.md`

### Availability
Active from the **next conversation/task** onwards (not the current context window).
