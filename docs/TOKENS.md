# Token Usage — Building Brainstash with Claude Code

_Generated 2026-10-28T12:34 by `tools/token_report.py`._

- Transcripts read: **2** (main session + subagents)
- Assistant API turns: **120**
- Time span: 2026-10-28T00:39:27.435Z → 2026-10-28T01:34:03.142Z
- **Grand total tokens: 20,957,476**
  - Fresh input: 244
  - Output: 119,936
  - Cache writes: 255,535
  - Cache reads: 20,581,761

| Model | Input | Output | Cache write | Cache read | Total |
|---|---|---|---|---|---|
| claude-opus-5-5 | 234 | 114,922 | 223,762 | 20,497,934 | 20,836,852 |
| claude-sonnet-5-5 | 10 | 5,014 | 31,773 | 83,827 | 120,624 |

Cache reads dominate because each turn re-reads the cached conversation; they are
billed at a fraction of fresh input. Output tokens are what Claude actually wrote.
**Note on models:** everything ran on Claude Opus 5.5 except the independent security-review
sub-agent, which ran on Claude Sonnet 5.5 because its agent definition pins that model and it
wasn't overridden (~0.6% of tokens). See decision D29.

**Excluded:** the time spent waiting for Xcode to download; design canvas rendering on
claude.ai (not part of this session's API usage).
