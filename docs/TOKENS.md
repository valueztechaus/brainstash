# Token Usage — Building Brainstash with Claude Code

_Generated 2026-10-28T12:44 by `tools/token_report.py`._

- Transcripts read: **2** (main session + subagents)
- Assistant API turns: **137**
- Time span: 2026-10-28T00:39:27.435Z → 2026-10-28T01:44:39.962Z
- **Grand total tokens: 25,451,729**
  - Fresh input: 278
  - Output: 139,308
  - Cache writes: 282,110
  - Cache reads: 25,030,033

| Model | Input | Output | Cache write | Cache read | Total |
|---|---|---|---|---|---|
| claude-opus-5-5 | 268 | 134,294 | 250,337 | 24,946,206 | 25,331,105 |
| claude-sonnet-5-5 | 10 | 5,014 | 31,773 | 83,827 | 120,624 |

Cache reads dominate because each turn re-reads the cached conversation; they are
billed at a fraction of fresh input. Output tokens are what Claude actually wrote.
**Note on models:** everything ran on Claude Opus 5.5 except the independent security-review
sub-agent, which ran on Claude Sonnet 5.5 because its agent definition pins that model and it
wasn't overridden (~0.6% of tokens). See decision D29.

**Excluded:** the time spent waiting for Xcode to download; design canvas rendering on
claude.ai (not part of this session's API usage).
