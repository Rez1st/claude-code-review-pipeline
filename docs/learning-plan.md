# 2-Week Learning Plan

Structured alongside building the `claude-code-review-pipeline` POC.
~1–1.5 hrs/day. Tailored for a .NET developer with prior AI app experience.

## Week 1 — Understand Claude + scaffold the backend

| Day | Study | Duration | POC task |
|---|---|---|---|
| Mon | [Introduction to Claude](https://www.pluralsight.com/courses/introduction-claude) | 25 min | Create repo, write README, architecture diagram |
| Tue | [Prompt Engineering for Developers](https://www.pluralsight.com/courses/anthropic-prompt-engineering-developers) | 18 min | Design code review prompt + output schema |
| Wed | [Prompt engineering deep-dive](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/overview) (Anthropic docs) | ~60 min | Scaffold ASP.NET Core API + docker-compose |
| Thu | [Anthropic API Introduction](https://www.pluralsight.com/courses/anthropic-api-introduction) | 48 min | Wire up Anthropic.SDK, basic streaming test |
| Fri | [Claude for Developers path](https://www.pluralsight.com/paths/anthropic-claude-3-for-developers) | ~60 min | Build .NET Worker Service |
| Sat | Build day | ~2 hrs | SignalR hub + end-to-end streaming test |
| Sun | Rest / catch-up | — | Push week 1 to GitHub |

**Milestone:** Code → API → Service Bus → Worker → Claude → SignalR. Working end-to-end.

---

## Week 2 — Deepen knowledge + ship the React frontend

| Day | Study | Duration | POC task |
|---|---|---|---|
| Mon | [Claude Opus: Capabilities for Developers](https://www.pluralsight.com/courses/first-look-anthropic-claude-opus-4-5) | 15 min | Scaffold React app, connect SignalR |
| Tue | [Anthropic Academy — API & MCP](https://anthropic.skilljar.com) | ~60 min | Monaco editor + live review panel |
| Wed | Tool use / function calling (hands-on) | ~90 min | Structured JSON tool response |
| Thu | [Claude Code path](https://www.pluralsight.com/paths/claude-code) | 45 min | Write unit tests with Claude Code |
| Fri | Polish + load testing | ~90 min | Retry logic, back-pressure, rate limiting |
| Sat | Ship it | ~2 hrs | Final README, demo GIF, tag v1.0 |
| Sun | Reflect + share | — | LinkedIn post / internal blog |

**Milestone:** Public repo, live demo, ready to present.

---

## Key resources

- [Anthropic docs](https://docs.anthropic.com) — prompt engineering, tool use, streaming
- [Anthropic Academy](https://anthropic.skilljar.com) — free courses with certificates
- [Anthropic.SDK NuGet](https://www.nuget.org/packages/Anthropic.SDK) — official C# client
- [@microsoft/signalr](https://www.npmjs.com/package/@microsoft/signalr) — SignalR React client
- [Monaco Editor](https://microsoft.github.io/monaco-editor/) — VS Code editor in browser
