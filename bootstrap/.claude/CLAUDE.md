# Claude Desktop — Session Bootstrap
# Deploy to C:\dev\.claude\CLAUDE.md on each workstation
# Auto-loaded by Claude Desktop when working directory is C:\dev
# Updated: 2026-02-16

## YOU ARE PROBABLY ON WINDOWS. VERIFY FIRST.

Do NOT assume you are sandboxed. Do NOT test bash_tool first.
Run this IMMEDIATELY before saying anything to the user:

    tool_search("filesystem windows execute command")

If you find UDC tools, read C:\dev\claude_start.json and follow its protocol.
If you find nothing, say: "I don't have filesystem access. I am web Claude."

## After verification, load context:
1. C:\dev\ksnlabs\.ai\buffer.jsonld (what happened last, what's next)
2. C:\dev\todo.json (active issue/task queue)
3. Latest file in C:\dev\ksnlabs\engram\learnings\
4. Latest file in C:\dev\ksnlabs\engram\workflows\

## What kills sessions:
- Claiming capabilities without running tool_search first
- Reading every handover file instead of just the buffer
- Fixing things without being asked
- Using bash_tool and concluding you're on Linux
