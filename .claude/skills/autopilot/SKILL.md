---
name: autopilot
description: Temporarily suspends the plan-mode/confirmation ceremony for regular dev work on this project for a 1-hour window, so implementation can proceed without stopping to ask first. Destructive/hard-to-reverse actions (force-push, reset --hard, deleting files/branches, etc.) still require confirmation regardless. Invoke with /autopilot.
---

When invoked:

1. Run `date +%s` via Bash to get the current epoch time. Compute `expiry = now + 3600` (1 hour).
2. Write `expiry` to `.claude/autopilot_expiry` (plain text, just the number). This file is local/ephemeral session state — it's already excluded via `.git/info/exclude`, not the repo's tracked `.gitignore`.
3. Tell the user autopilot is active until the computed wall-clock end time (convert epoch to a human-readable local time and state it plainly), and that it lapses back to normal behavior automatically after that.

While autopilot is active (a non-expired `.claude/autopilot_expiry` file exists):
- Skip `EnterPlanMode` and `AskUserQuestion` ceremony for ordinary feature/dev work on this project — implement directly using your best judgment on approach, and briefly explain what you did afterward instead of asking beforehand.
- Before starting any non-trivial task, re-check the current time (`date +%s`) against the stored expiry. If expired: delete `.claude/autopilot_expiry`, tell the user autopilot has lapsed, and resume normal plan-first behavior for anything further in the same response.
- The safety floor from the system instructions still applies without exception — autopilot only waives the "align on approach first" step for regular reversible dev work. Still stop and confirm before: force-push, `git reset --hard`, deleting files/branches/uncommitted work, bypassing hooks (`--no-verify`), or modifying shared/production infrastructure.
- Keep the user briefly informed as you go (what changed, what's next) — autopilot removes the approval *gate*, not communication.

To end autopilot early, the user can just say so directly, or let the hour lapse on its own.
