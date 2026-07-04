---
name: todaymode
description: For the rest of today, minimize how often work stops to ask the user something — skip plan-mode ceremony for regular dev work AND make your own best-judgment call instead of using AskUserQuestion wherever a reasonable default exists. Destructive/hard-to-reverse actions still require confirmation regardless. Invoke with /todaymode.
---

When invoked:

1. Run `date +%s` via Bash to get the current epoch time. Compute the end of the current local day (next midnight) as the expiry.
2. Write that expiry to `.claude/todaymode_expiry` (plain text, just the epoch number). This file is local/ephemeral session state — add `**/.claude/todaymode_expiry` to `.git/info/exclude` if not already present (matching how `.claude/autopilot_expiry` is handled), not the repo's tracked `.gitignore`.
3. Tell the user todaymode is active until midnight (state the actual local time plainly) and will lapse back to normal behavior automatically after that.

While todaymode is active (a non-expired `.claude/todaymode_expiry` file exists):
- Skip `EnterPlanMode` ceremony for ordinary feature/dev work on this project — implement directly, explaining what you did afterward instead of asking beforehand. (Same behavior as the `/autopilot` skill, if that's also active — todaymode is the broader, longer-lived version of the same idea.)
- **Prefer making a reasonable default call over calling `AskUserQuestion`.** When a request has more than one plausible approach, pick the one that best fits patterns already established in this project/conversation, state the assumption you made in your summary afterward, and move on — don't stop to ask unless the choice is genuinely load-bearing (e.g. would be expensive/awkward to undo, or the options are so divergent that guessing wrong wastes significant work).
- Before starting any non-trivial task, re-check the current time (`date +%s`) against the stored expiry. If expired: delete `.claude/todaymode_expiry`, tell the user todaymode has lapsed, and resume normal behavior (plan-first, ask-when-ambiguous) for anything further in the same response.
- The safety floor from the system instructions still applies without exception — still confirm before: force-push, `git reset --hard`, deleting files/branches/uncommitted work, bypassing hooks (`--no-verify`), or modifying shared/production infrastructure. Also still confirm before anything that costs the user real money or creates external accounts/services on their behalf (e.g. don't sign up for a paid tier, don't send anything to a live audience) — todaymode reduces *questions about approach*, not the standing checks around risk and spend.
- Keep the user briefly informed as you go (what changed, what's next, what assumption you made) — todaymode removes the up-front question, not the summary afterward.

To end todaymode early, the user can just say so directly, or let midnight lapse it automatically.
