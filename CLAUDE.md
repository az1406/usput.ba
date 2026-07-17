# Claude Code Setup

## Projekat
**Usput.ba** - Turistička platforma za Bosnu i Hercegovinu sa AI-powered content generacijom.

## Tech Stack
- Ruby 3.3+ / Rails 8
- PostgreSQL + pgvector
- Tailwind CSS
- Hotwire (Turbo + Stimulus)

## Brzi start

```bash
# Development
bin/rails server
bin/rails console
bin/rails test

# Platform CLI (DSL queries)
bin/platform exec 'locations | count'
bin/platform exec 'experiences | where(city: "Sarajevo") | limit(5)'
```

## Struktura

```
app/
├── controllers/
│   ├── curator/          # Curator dashboard
│   └── new_design/       # Public pages
├── models/               # ActiveRecord modeli
├── services/
│   └── ai/              # AI servisi (generators, enrichers)
├── views/
│   ├── curator/         # Curator UI
│   └── new_design/      # Public UI
└── javascript/
    └── controllers/     # Stimulus kontroleri

lib/
└── platform/            # Platform brain (DSL, tools)

.claude/
├── agents/              # Agent persone
├── planning/            # Planovi i dokumentacija
└── CLAUDE.md           # Detaljne instrukcije
```

## Agenti

Pogledaj `AGENTS.md` za listu dostupnih agenata.

## Dokumentacija

| Dokument | Lokacija |
|----------|----------|
| Detaljne instrukcije | `.claude/CLAUDE.md` |
| Agent persone | `.claude/agents/` |
| Planovi | `.claude/planning/` |
| Vizija | `.claude/planning/VISION.md` |

## Pravila

1. **Testovi obavezni** - ne commitaj kod bez testova
2. **Prati patterns** - koristi postojeće obrasce u kodu
3. **Pitaj kad nisi siguran** - bolje pitati nego pogriješiti
4. **Bosanski sadržaj** - ijekavica, "historija" ne "istorija"

<!-- brain:managed:start -->

## Brain — synthesis layer for this repo

This repo (`usput.ba`) is described and tracked in **`/home/muhamed/projects/brain`**, a
local LLM-maintained knowledge base. The brain holds the *why* and *how*
at a level the source alone doesn't surface — architecture, conventions,
decision history (ADRs), in-flight initiatives (PRDs), cross-product
overlaps.

### Read the brain BEFORE searching source

When asked about this repo's architecture, conventions, "why does X work
this way," or any feature spanning multiple files — read brain pages first.
Source code is the implementation; the brain explains the shape.

**Top entry points for `usput.ba`:**

- `/home/muhamed/projects/brain/wiki/usput.ba/index.md` — repo navigation hub
- `/home/muhamed/projects/brain/wiki/usput.ba/permanent/architecture.md` — durable shape
- `/home/muhamed/projects/brain/wiki/usput.ba/permanent/interfaces.md` — external contracts
- `/home/muhamed/projects/brain/wiki/usput.ba/permanent/domain.md` — vocabulary + entities
- `/home/muhamed/projects/brain/wiki/usput.ba/permanent/purpose.md` — what this repo exists for
- `/home/muhamed/projects/brain/wiki/usput.ba/state.md` — Now / Perceived / Target trajectory

**Decisions and initiatives:**

- `/home/muhamed/projects/brain/wiki/usput.ba/adrs/` — accepted ADRs (kind: decision)
- `/home/muhamed/projects/brain/wiki/usput.ba/prds/` — committed PRDs (kind: initiative)
- `/home/muhamed/projects/brain/wiki/usput.ba/ai-suggestions/` — agent-authored drafts
  awaiting human review; **not** decisions, **not** product state

### Cross-product context

Decisions affecting multiple repos live at:

- `/home/muhamed/projects/brain/wiki/org/` — cross-cutting (auth / AI surfaces / CI /
  domain mapping / frontend stacks / runtime topology)
- `/home/muhamed/projects/brain/wiki/insights/` — patterns from feedback / observed work
- `/home/muhamed/projects/brain/wiki/_overlaps/` — surfaced cross-team duplications

### Querying the brain

If `python3 /home/muhamed/projects/brain/tools/brain.py search '<query>'` is available,
prefer it over manual file walks. It returns ranked pages with title,
kind, confidence, score, excerpt.

### When to write to the brain

The brain has its own write workflow — never edit `/home/muhamed/projects/brain/wiki/`
directly from this repo. Instead, `cd /home/muhamed/projects/brain` and use the brain's
slash commands (`/shape`, `/in`, `/capture`).

<!-- brain:managed:manifest version="1" repo="usput.ba" generated="2026-07-13" -->
<!-- brain:managed:end -->

