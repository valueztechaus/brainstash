# Token Usage — Building Brainstash with Claude Code

_Generated 2026-10-28T12:29 by `tools/token_report.py`._

- Transcripts read: **2** (main session + subagents)
- Assistant API turns: **105**
- Time span: 2026-10-28T00:39:27.435Z → 2026-10-28T01:29:36.565Z
- **Grand total tokens: 17,214,418**
  - Fresh input: 214
  - Output: 114,901
  - Cache writes: 247,121
  - Cache reads: 16,852,182

| Model | Input | Output | Cache write | Cache read | Total |
|---|---|---|---|---|---|
| claude-opus-5-5 | 204 | 109,887 | 215,348 | 16,768,355 | 17,093,794 |
| claude-sonnet-5-5 | 10 | 5,014 | 31,773 | 83,827 | 120,624 |

Cache reads dominate because each turn re-reads the cached conversation; they are
billed at a fraction of fresh input. Output tokens are what Claude actually wrote.
