# claude-code-review-pipeline

> **Learn & Build** — A 2-week hands-on learning project pairing Pluralsight/Anthropic courses with a real POC.  
> Built by [@Rez1st](https://github.com/Rez1st) · Powered by [Claude](https://claude.ai) · April 2026

---

## What is this?

An **async, high-throughput code review pipeline** that uses Claude AI as the reviewer.  
You paste (or push) code → it lands on a queue → a .NET Worker Service processes it → Claude reviews it → the result streams back to a React dashboard in real time via SignalR.

This repo is both a **working POC** and a **learning artefact** — every folder maps to a week of study.

---

## Architecture

```
React (Vite + TS)
  │  Monaco editor + live review panel
  │
  ▼
ASP.NET Core Web API
  │  POST /review  →  enqueue job
  │  SignalR hub   ←  stream results back
  │
  ▼
RabbitMQ (docker-compose)
  │
  ▼
.NET Worker Service
  │  Dequeues job
  │  Calls Claude API (streaming)
  │  Parses structured JSON response
  │
  ▼
Claude API (claude-sonnet-4-6)
  │  Returns: issues[], severity, suggestions[]
  │
  ▼
SignalR  →  React live feed
```

---

## Tech stack

| Layer | Technology |
|---|---|
| Frontend | React 18, Vite, TypeScript, Monaco Editor, @microsoft/signalr |
| API | ASP.NET Core 8, SignalR |
| Worker | .NET 8 Worker Service, Anthropic.SDK (NuGet) |
| Queue | RabbitMQ (local docker-compose) / Azure Service Bus (prod) |
| AI | Claude Sonnet (claude-sonnet-4-6) via Anthropic API |

---

## Repo structure

```
claude-code-review-pipeline/
├── src/
│   ├── Api/                  # ASP.NET Core Web API + SignalR hub
│   ├── Worker/               # .NET Worker Service (queue consumer)
│   └── Frontend/             # React + Vite app
├── docker-compose.yml        # RabbitMQ local dev
├── docs/
│   └── learning-plan.md      # Full 2-week learning plan (see below)
└── README.md
```

---

## Getting started

### Prerequisites
- .NET 8 SDK
- Node 20+
- Docker Desktop
- Anthropic API key → [console.anthropic.com](https://console.anthropic.com)

### Run locally

```bash
# 1. Start RabbitMQ
docker-compose up -d

# 2. Set your API key
export ANTHROPIC__APIKEY=sk-ant-...

# 3. Start the API
cd src/Api && dotnet run

# 4. Start the Worker
cd src/Worker && dotnet run

# 5. Start the frontend
cd src/Frontend && npm install && npm run dev
```

Open http://localhost:5173, paste some C# code, and watch the review stream in.

---

## Claude prompt design

The Worker sends code to Claude with a structured system prompt:

```
You are a senior .NET code reviewer. Review the submitted code and respond ONLY
with valid JSON matching this schema:

{
  "language": "string",
  "issues": [
    {
      "line": number | null,
      "severity": "critical" | "warning" | "info",
      "title": "string",
      "description": "string",
      "suggestion": "string"
    }
  ],
  "summary": "string",
  "score": number  // 0–10
}
```

Severity definitions:
- **critical** — bugs, security issues, data loss risk
- **warning** — code smells, performance, maintainability
- **info** — style, naming, minor improvements

---

## Learning plan

This project was built over 2 weeks alongside structured learning. Each day has a study session and a POC task.

### Week 1 — Understand Claude + scaffold the backend

| Day | Study | POC task |
|---|---|---|
| Mon | Introduction to Claude (Pluralsight, 25 min) | Create repo, write README, architecture diagram |
| Tue | Prompt Engineering for Developers (Pluralsight, 18 min) | Design the code review prompt + output schema |
| Wed | Prompt engineering deep-dive (docs.anthropic.com) | Scaffold ASP.NET Core API + RabbitMQ docker-compose |
| Thu | Anthropic API Introduction (Pluralsight, 48 min) | Wire up Anthropic.SDK, basic streaming test in C# |
| Fri | Claude for Developers path (Pluralsight, ~60 min) | Build .NET Worker Service — dequeues + calls Claude |
| Sat | Build day | Add SignalR hub, stream Claude responses back to API caller |
| Sun | Rest / catch-up | Push week 1 to GitHub |

**Week 1 milestone:** Repo is live. Code submitted via API → queue → Worker → Claude → SignalR stream. End-to-end working.

---

### Week 2 — Deepen knowledge + ship the React frontend

| Day | Study | POC task |
|---|---|---|
| Mon | Claude Opus capabilities for Developers (Pluralsight, 15 min) | Scaffold React app (Vite + TS), connect SignalR hub |
| Tue | Anthropic Academy — API & MCP (anthropic.skilljar.com, free) | Build Monaco editor UI + live review panel in React |
| Wed | Tool use / function calling (hands-on) | Add structured JSON tool to Claude response |
| Thu | Claude Code first look (Pluralsight, 45 min) | Use Claude Code to write unit tests for the Worker |
| Fri | Polish + load testing | Add retry logic, back-pressure handling, rate limit awareness |
| Sat | Ship it | Write final README, record demo GIF, tag v1.0 |
| Sun | Reflect + share | Write a short post — consolidates the learning |

**Week 2 milestone:** Public GitHub repo with working React + ASP.NET Core + RabbitMQ + Claude streaming pipeline. Ready to demo.

---

## Key Pluralsight courses

| Course | Duration | Link |
|---|---|---|
| Introduction to Claude | 25 min | [pluralsight.com](https://www.pluralsight.com/courses/introduction-claude) |
| Prompt Engineering for Developers | 18 min | [pluralsight.com](https://www.pluralsight.com/courses/anthropic-prompt-engineering-developers) |
| Anthropic API Introduction | 48 min | [pluralsight.com](https://www.pluralsight.com/courses/anthropic-api-introduction) |
| Anthropic Claude for Developers (path) | ~2 hrs | [pluralsight.com](https://www.pluralsight.com/paths/anthropic-claude-3-for-developers) |
| Claude Opus: Capabilities for Developers | 15 min | [pluralsight.com](https://www.pluralsight.com/courses/first-look-anthropic-claude-opus-4-5) |
| Claude Code (path) | ~2 hrs | [pluralsight.com](https://www.pluralsight.com/paths/claude-code) |

Free resource: [Anthropic Academy](https://anthropic.skilljar.com) — API, MCP, Claude Code (with certificates)

---

## Resources

- [Anthropic docs](https://docs.anthropic.com) — prompt engineering, tool use, streaming
- [Anthropic.SDK NuGet](https://www.nuget.org/packages/Anthropic.SDK) — official C# client
- [@microsoft/signalr npm](https://www.npmjs.com/package/@microsoft/signalr) — SignalR client for React
- [Monaco Editor](https://microsoft.github.io/monaco-editor/) — VS Code editor in the browser

---

## Licence

MIT
