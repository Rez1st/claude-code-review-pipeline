# CLAUDE.md — AI Context File

> This file is the single source of truth for any AI assistant (Claude, Copilot, Cursor, etc.)
> picking up work on this project. Read this first before touching any code.

---

## Project summary

**claude-code-review-pipeline** is an async, high-throughput AI code review system.
Users submit code via a React frontend → it lands on an Azure Service Bus queue →
a .NET 8 Worker Service dequeues it and calls the Claude API → the structured review
streams back to the React dashboard in real time via Azure SignalR Service.

This is simultaneously a **learning project** (2-week Pluralsight + Anthropic Academy study plan)
and a **production-ready POC** deployable to Azure via Bicep + GitHub Actions.

**Owner:** @Rez1st  
**Stack:** React 18 + Vite + TypeScript · ASP.NET Core 8 · .NET 8 Worker Service · Azure Service Bus · Azure SignalR Service · Claude API (Anthropic)  
**Repo:** https://github.com/Rez1st/claude-code-review-pipeline

---

## Architecture

```
[React Frontend]
  Monaco code editor
  Live streaming review panel
       │
       │ POST /api/review
       ▼
[ASP.NET Core Web API]  ──────────────────────────────┐
  Validates request                                    │
  Assigns correlationId                                │
  Publishes message to Service Bus                     │
  Returns 202 Accepted + correlationId                 │
       │                                               │
       │ Azure Service Bus                             │
       │ Queue: code-review-jobs                       │
       ▼                                               │
[.NET Worker Service]                                  │
  Dequeues message                                     │
  Builds system prompt (see Prompt Design below)       │
  Calls Claude API with streaming enabled              │
  Parses structured JSON response                      │
  Publishes chunks to SignalR hub by correlationId     │
       │                                               │
       │ Azure SignalR Service                         │
       └───────────────────────────────────────────────┘
       ▼
[React Frontend]
  Receives streaming chunks via SignalR
  Renders issues, severity badges, suggestions live
```

---

## Folder structure

```
claude-code-review-pipeline/
├── src/
│   ├── Api/                        # ASP.NET Core 8 Web API
│   │   ├── Controllers/
│   │   │   └── ReviewController.cs # POST /api/review
│   │   ├── Hubs/
│   │   │   └── ReviewHub.cs        # SignalR hub
│   │   ├── Models/
│   │   │   ├── ReviewRequest.cs
│   │   │   └── ReviewResult.cs
│   │   ├── Services/
│   │   │   └── QueuePublisher.cs   # Service Bus publisher
│   │   └── Program.cs
│   │
│   ├── Worker/                     # .NET 8 Background Worker Service
│   │   ├── Worker.cs               # IHostedService — dequeues + orchestrates
│   │   ├── Services/
│   │   │   ├── ClaudeReviewService.cs  # Calls Anthropic API, streams response
│   │   │   └── SignalRNotifier.cs      # Pushes chunks to SignalR hub
│   │   ├── Models/
│   │   │   └── ReviewJob.cs
│   │   ├── Prompts/
│   │   │   └── CodeReviewPrompt.cs # System prompt builder
│   │   ├── Dockerfile
│   │   └── Program.cs
│   │
│   └── Frontend/                   # React 18 + Vite + TypeScript
│       ├── src/
│       │   ├── components/
│       │   │   ├── CodeEditor.tsx   # Monaco editor wrapper
│       │   │   ├── ReviewPanel.tsx  # Live streaming results
│       │   │   ├── IssueBadge.tsx   # severity colour-coded badge
│       │   │   └── ScoreGauge.tsx   # 0-10 score display
│       │   ├── hooks/
│       │   │   └── useSignalR.ts    # SignalR connection hook
│       │   ├── services/
│       │   │   └── reviewApi.ts     # POST /api/review
│       │   ├── types/
│       │   │   └── review.ts        # TypeScript interfaces
│       │   └── App.tsx
│       ├── package.json
│       └── vite.config.ts
│
├── infra/                          # Azure infrastructure (Bicep)
│   ├── main.bicep
│   ├── parameters.dev.json
│   └── modules/
│       ├── api.bicep               # App Service + SignalR Service
│       ├── messaging.bicep         # Service Bus namespace + queues
│       ├── worker.bicep            # Container Apps + scaling rules
│       ├── frontend.bicep          # Static Web Apps
│       └── keyvault.bicep          # Key Vault + secrets
│
├── .github/
│   └── workflows/
│       └── deploy.yml              # CI/CD: Bicep → API → Worker → Frontend
│
├── docs/
│   └── learning-plan.md
│
├── docker-compose.yml              # Local dev: RabbitMQ substitute
├── CLAUDE.md                       # ← You are here
└── README.md
```

---

## Claude prompt design

### System prompt (Worker/Prompts/CodeReviewPrompt.cs)

```
You are a senior software engineer and code reviewer with deep expertise in .NET, C#,
and software architecture. You review code submitted by developers and return a
structured JSON review.

Rules:
- Respond ONLY with valid JSON. No markdown, no preamble, no explanation outside the JSON.
- Be specific: reference line numbers where possible.
- Be constructive: every issue must include a concrete suggestion.
- Score fairly: 10 = production-ready, 0 = dangerous/broken.

Response schema:
{
  "language": "string",           // detected language e.g. "csharp", "typescript"
  "score": number,                // 0–10 overall quality score
  "summary": "string",           // 2-3 sentence executive summary
  "issues": [
    {
      "line": number | null,
      "severity": "critical" | "warning" | "info",
      "title": "string",
      "description": "string",
      "suggestion": "string"
    }
  ]
}

Severity guide:
- critical: bugs, security vulnerabilities, data loss risk, unhandled exceptions
- warning:  performance issues, code smells, SOLID violations, missing null checks
- info:     style, naming conventions, minor improvements, documentation gaps
```

### Streaming approach
The Worker calls `client.Messages.StreamAsync(...)` from `Anthropic.SDK`.
As chunks arrive they are buffered until a complete JSON object is accumulated,
then deserialized and forwarded to SignalR. This gives the frontend a smooth
progressive render rather than waiting for the full response.

---

## Key configuration

### API (appsettings.json / environment variables)
```json
{
  "Azure": {
    "SignalR": {
      "ConnectionString": "<from Key Vault>"
    }
  },
  "ServiceBus": {
    "ConnectionString": "<from Key Vault>",
    "QueueName": "code-review-jobs"
  }
}
```

### Worker (environment variables)
```
Anthropic__ApiKey         = <from Key Vault>
ServiceBus__ConnectionString = <from Key Vault>
ServiceBus__QueueName     = code-review-jobs
SignalR__HubUrl           = https://<api-host>/hubs/review
```

### Local dev (.env / docker-compose)
```
ANTHROPIC__APIKEY=sk-ant-...
RABBITMQ_HOST=localhost     # docker-compose RabbitMQ (swapped for Service Bus in Azure)
```

---

## Implemented features (v0 — in progress)

- [ ] ASP.NET Core API scaffolded with POST /api/review endpoint
- [ ] Azure Service Bus queue publisher (QueuePublisher.cs)
- [ ] SignalR hub (ReviewHub.cs) wired to Azure SignalR Service
- [ ] .NET Worker Service — dequeues Service Bus messages
- [ ] ClaudeReviewService — streaming call to Anthropic API
- [ ] Structured JSON prompt with severity schema
- [ ] React app scaffolded (Vite + TypeScript)
- [ ] Monaco editor component
- [ ] SignalR client hook (useSignalR.ts)
- [ ] Live streaming ReviewPanel component
- [ ] Azure Bicep infra (main + all modules)
- [ ] GitHub Actions CI/CD pipeline

---

## Planned features (backlog)

### Phase 1 — Core improvements
- [ ] **Multi-language support** — extend prompt to handle TypeScript, Python, SQL etc.
- [ ] **Review history** — store results in Azure Cosmos DB (NoSQL, easy to add)
- [ ] **User authentication** — Azure AD B2C or GitHub OAuth
- [ ] **Rate limiting** — per-user queue depth limit to protect Anthropic API costs
- [ ] **Dead letter monitoring** — alert when messages hit dead-letter queue

### Phase 2 — Intelligence
- [ ] **Context-aware review** — accept multiple files, not just a single snippet
- [ ] **Diff review mode** — submit a git diff, review only changed lines
- [ ] **Project rules** — let users define custom review rules (e.g. "we use NodaTime, not DateTime")
- [ ] **Trend dashboard** — track score over time per file/repo
- [ ] **PR integration** — GitHub webhook triggers auto-review on PR open

### Phase 3 — Scale & polish
- [ ] **Batch processing** — review entire repos via GitHub App
- [ ] **Team workspaces** — shared review history, team rules
- [ ] **VS Code extension** — trigger review from within the editor
- [ ] **Export** — download review as PDF or markdown
- [ ] **Webhook notifications** — Slack / Teams alert when review completes

---

## Azure infrastructure summary

| Resource | Name pattern | SKU (POC) |
|---|---|---|
| Resource Group | rg-claude-review-poc | — |
| App Service Plan | asp-claude-review-dev | B1 |
| App Service (API) | app-claude-review-dev | — |
| Azure SignalR Service | sigr-claude-review-dev | Free_F1 |
| Service Bus Namespace | sb-claude-review-dev | Basic |
| Service Bus Queue | code-review-jobs | — |
| Service Bus Queue | code-review-jobs-results | — |
| Container Apps Env | cae-claude-review-dev | Consumption |
| Container App (Worker) | ca-worker-claude-review-dev | 0.5 CPU / 1Gi |
| Static Web Apps | swa-claude-review-dev | Free |
| Key Vault | kvclaudereviewdev | Standard |
| Container Registry | acrclaudereviewdev | Basic |

Scale rules: Worker scales 0→10 replicas based on Service Bus queue depth (threshold: 5 messages).

---

## CI/CD

GitHub Actions workflow (`.github/workflows/deploy.yml`) runs on every push to `master`:
1. Deploy Bicep infra (idempotent)
2. Build + deploy API to App Service
3. Build + push Worker Docker image to ACR → update Container App
4. Build React app with API URL injected → deploy to Static Web Apps

### Required GitHub secrets
```
AZURE_CREDENTIALS              # az ad sp create-for-rbac output (JSON)
ANTHROPIC_API_KEY              # sk-ant-...
AZURE_STATIC_WEB_APPS_API_TOKEN # from Static Web Apps resource in portal
```

---

## Local development

```bash
# 1. Start local queue (RabbitMQ via Docker)
docker-compose up -d

# 2. API
cd src/Api
dotnet run

# 3. Worker
cd src/Worker
ANTHROPIC__APIKEY=sk-ant-... dotnet run

# 4. Frontend
cd src/Frontend
npm install && npm run dev
# → http://localhost:5173
```

---

## Conventions & decisions

- **Correlation ID pattern** — every review job gets a GUID on entry. This ID flows through
  Service Bus message metadata → Worker → SignalR group. The React frontend joins the
  SignalR group for its correlationId and receives only its own review stream.

- **No database in v0** — results are streamed and displayed; not persisted. Cosmos DB is
  the planned addition (see Phase 1 backlog).

- **Secrets never in code or config files** — all secrets live in Key Vault. App Service and
  Container Apps access them via Managed Identity + RBAC (no connection strings in env vars
  in production).

- **Service Bus over RabbitMQ in Azure** — RabbitMQ is used locally via docker-compose only.
  The Worker's queue abstraction (`IQueueConsumer`) allows swapping implementations.

- **Streaming JSON** — Claude streams tokens; the Worker buffers until a complete JSON object
  is available, then deserializes. This is intentional — partial JSON is not forwarded to
  avoid parse errors on the frontend.

---

## Learning context

This project was built alongside a structured 2-week learning plan:
- **Pluralsight paths:** Anthropic Claude, Anthropic Claude for Developers, Claude Code
- **Free:** Anthropic Academy (anthropic.skilljar.com) — API, MCP, Claude Code
- **Docs:** docs.anthropic.com — prompt engineering, tool use, streaming

Each feature in this repo corresponds to a day of learning. See `docs/learning-plan.md`
and the README for the full schedule.

---

## How to pick up this project (for any AI assistant)

1. Read this file (`CLAUDE.md`) fully before writing any code
2. Check the `Implemented features` section to see what exists
3. Check the `Planned features` backlog to understand what comes next
4. Follow the **Correlation ID pattern** — it is the backbone of the streaming architecture
5. Keep secrets in Key Vault — never hardcode or log them
6. The Worker's `IQueueConsumer` abstraction must be respected — do not call Service Bus directly
7. All new features should be added to the backlog in this file when planned, moved to implemented when done
8. Update `docs/learning-plan.md` if the learning schedule changes

---

## Living document rules — MUST follow after every session

> These rules apply to every AI assistant working on this repo, without exception.
> The repo is the single source of truth. Keep it that way.

### After every coding session
- **Move completed items** from `Planned features` → `Implemented features` in this file
- **Add any new decisions** to the `Conventions & decisions` section (e.g. a new pattern, a library choice, a naming rule)
- **Update the folder structure** diagram if new files or folders were added
- **Update `README.md`** — the Getting Started steps, Tech Stack table, and architecture diagram must always reflect the actual current state of the code

### After every learning session
- **Tick off completed days** in `docs/learning-plan.md`
- **Add notes** under the relevant day if something important was learned (a gotcha, a useful pattern, a doc link)

### When adding a new planned feature
- Add it to the correct phase in `Planned features` with a `[ ]` checkbox
- Include a one-line description of what it does and why it exists

### When the Azure infra changes
- Update the **Azure infrastructure summary** table in this file
- Update `infra/README.md` with any new resources, changed SKUs, or revised cost estimates
- Update `infra/parameters.dev.json` if new parameters are added

### README sync rule
`README.md` is the public face of the repo. It must always match reality:
- Architecture diagram reflects the actual flow
- Tech Stack table lists what is actually installed and used
- Getting Started steps actually work
- Progress Tracker checkboxes are kept current

### The golden rule
**If you built it, document it. If you changed it, update it. If you removed it, delete the reference.**
The next person (or AI) to open this repo should be able to understand the full picture
from `CLAUDE.md` + `README.md` alone, without asking anyone.
