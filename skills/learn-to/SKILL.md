---
name: learn-to
description: Review recent conversation messages and append a behavioural note to ~/.agents/behaviour.md
---

When invoked as a skill block, follow these exact steps and nothing else:

1. Inspect the last 6 messages of the current conversation (user and assistant messages). Summarize the behaviour to record into a short note (1-4 lines title + 2-6 lines body). Focus on what the assistant did or should do differently — e.g. tone, verbosity, missing checks, preferred phrasing, mistaken assumptions, safety concerns, or follow-up actions.

2. Build a markdown entry with this format:

---
### TIMESTAMP — short title

body text (2-6 lines)

context:
> (quote up to 2 short excerpts from the recent messages for traceability)

source: conversation
---

Replace TIMESTAMP with UTC ISO (YYYY-MM-DD HH:MM:SS UTC).

3. Call the helper script ./append-behaviour.sh and pass the whole entry via stdin. The helper script will atomically append it to ~/.agents/behaviour.md.

4. Return a single short assistant message confirming the write and showing the first line of the entry.

Usage examples:
<skill name="learn-to" location="~/.agents/skills/learn-to/SKILL.md">(skill body ignored)</skill>

Implementation notes for maintainers:
- Helper: append-behaviour.sh (in this directory) performs mkdir -p, locking, and atomic append.
- Keep the note concise and behaviour-focused. Do not include sensitive personal data.
