# Token Usage — Building Brainstash with Claude Code

_Generated 2026-10-28T16:35 by `tools/token_report.py`._

- Transcripts read: **2** (main session + subagents)
- Assistant API turns: **266**
- Time span: 2026-10-28T00:39:27.435Z → 2026-10-28T05:35:27.518Z
- **Grand total tokens: 46,500,359**
  - Fresh input: 540
  - Output: 239,496
  - Cache writes: 504,824
  - Cache reads: 45,755,499

| Model | Input | Output | Cache write | Cache read | Total |
|---|---|---|---|---|---|
| claude-opus-5-5 | 530 | 234,482 | 473,051 | 45,671,672 | 46,379,735 |
| claude-sonnet-5-5 | 10 | 5,014 | 31,773 | 83,827 | 120,624 |

Cache reads dominate because each turn re-reads the cached conversation; they are
billed at a fraction of fresh input. Output tokens are what Claude actually wrote.

**Note on models:** everything ran on Claude Opus 5.5 except the independent security-review
sub-agent, which ran on Claude Sonnet 5.5 because its agent definition pins that model and it
wasn't overridden (~0.3% of tokens). See decision D29.

**Excluded:** the time spent waiting for Xcode to download; design canvas rendering on
claude.ai (not part of this session's API usage).
