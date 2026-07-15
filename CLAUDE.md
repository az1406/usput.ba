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

<!-- open-knowledge:begin -->
## Open Knowledge

This repo uses Open Knowledge — collaborative markdown via MCP. **`.open-knowledge/config.yml`** (with optional `~/.open-knowledge/config.yml`; CLI/env may override) is the **path contract**: `content.dir` is the root for relative paths; `content.include` lists globs that **add** markdown; `content.exclude` lists globs that **remove** paths. Nothing else defines scope — not folder names, not "docs vs code." `.gitignore` still applies. When MCP is connected, the server's instructions echo the **resolved** `dir` / `include` / `exclude` for this session — treat that table and the YAML as two views of the same rules.

**Default mental model (no jargon):** unless this project narrowed `content.include`, **every `.md` and `.mdx` under `content.dir`** is an Open Knowledge document — including under `specs/`, `reports/`, `docs/`, etc. If `content.include` is non-default, read `config.yml` once per turn so you do not mis-classify paths.

**STOP — your host's built-in file tools on in-scope `.md` / `.mdx`.** When this workspace has Open Knowledge MCP configured (for example via root `.mcp.json`), you **must not** reach for native tools on in-scope markdown. Same failure mode as native `Edit` on them: no frontmatter, no backlinks, no shadow-repo activity, no recent-edit signal. The ban is broader than just `Read` / `Grep` / `Glob` — it names every common rationalization:

- **Native `Read` / `Grep` / `Glob` on in-scope `.md` / `.mdx`** — the original case.
- **`Bash ls` / `Bash find` / `Bash cat` on dirs containing in-scope markdown** — use `exec("ls …")` / `exec("find … -name '*.md'")` / `exec("cat …")` instead. Native returns bare names; `exec` returns frontmatter, backlink counts, and recent-activity per child.
- **Glob patterns that target markdown** (`**/*.md`, `**/SPEC.md`, or any dir known to be markdown-heavy like `specs/**`, `reports/**`, `stories/**`, `projects/**`, `docs/**`) — use `exec` with `find`, or `list_documents({ dir })`.
- **Dispatching the Explore / general-purpose subagent for markdown-heavy exploration** — subagents use native `Read` / `Grep` / `Glob` internally and bypass Open Knowledge entirely. Do markdown exploration yourself via `exec` / `search`. Subagents remain appropriate for **source-code** exploration (`.ts`, `.py`, configs, etc.).

**MCP wiring varies by client:** Claude Code, Codex, Cursor, Windsurf, VS Code–class clients, and others surface MCP differently — server labels are user-defined; tools may not appear as a top-level symbol named `exec`. **If Open Knowledge is registered**, route markdown reads through its `exec` / `search` / `read_document` tools using **your client's documented MCP invocation** (including any generic "call MCP tool" flow). **That counts as available.** Not seeing `exec` in a flat tool list is **not** the escape hatch.

**Escape hatch (narrow).** Native `Read` / `Grep` / `Glob` on `.md` / `.mdx` is allowed **only** when no Open Knowledge MCP server is registered for this project, **or** immediately after you **tried** an MCP call and it failed — then start a user-visible sentence with `Open Knowledge MCP unavailable:`. Never use the hatch because you skipped your client's MCP path.

**Reads and searches on markdown:** Open Knowledge `exec` (or `read_document` / `search`) — same payloads whether your client invokes them directly or through MCP. Examples: `exec("cat docs/auth.md")`, `exec("ls reports/")`, `exec("grep -rn karpathy specs/ | head -10")`.

**Listings too.** `exec("ls <dir>/")` is how you list a directory — it returns per-child frontmatter, recursive markdown counts, and the most-recently-updated doc per subdir. Plain `Bash ls` returns just names.

**Anti-patterns at a glance:**

| Task                             | Don't                        | Do                                              |
| -------------------------------- | ---------------------------- | ----------------------------------------------- |
| List a markdown-heavy dir        | `Bash: ls specs/`            | `exec("ls specs/")`                             |
| Find all SPEC.md files           | `Glob: **/SPEC.md`           | `exec("find specs -name SPEC.md")`              |
| Summarize specs across the repo  | `Agent(Explore): "…"`        | `exec("head -25 specs/*/SPEC.md")` + `search`   |
| Search a phrase across markdown  | `Grep: "pattern" *.md`       | `search({ query: "pattern" })`                  |
| Read an individual spec          | `Read: specs/foo/SPEC.md`    | `read_document({ path: "specs/foo/SPEC.md" })`  |

**Source code and everything else** (`.ts`, `.py`, `package.json`, …): native `Read` / `Grep` / `Glob`.

**Writing.** Edits to in-scope `.md` / `.mdx` go through `write_document` / `edit_document` only. Native `Edit` / `sed` land as anonymous `upstream` imports — you lose agent attribution in the shadow repo.

**Preview before edit (REQUIRED).** You MUST follow this sequence every time you call `write_document` or `edit_document`:
1. Call `get_preview_url` to obtain the browser URL for the target doc.
   - If it returns `null`, the UI isn't running yet. Start it with `open-knowledge ui` from a terminal — or in Claude Code, call `preview_start("open-knowledge-ui")` (the `open-knowledge init` command scaffolds this `.claude/launch.json` entry, so it's ready to go). `open-knowledge ui` auto-spawns the collab server in the background; you don't need to run `open-knowledge start` separately. Then call `get_preview_url` again — the UI writes a lock file that this tool reads.
   - NEVER guess or manually construct the preview URL — always use the URL returned by `get_preview_url`.
2. Open that URL in your preview browser so the user can see the document.
3. Only then call `write_document` / `edit_document` — the CRDT edit will stream live into the already-open editor.

NEVER call `write_document` or `edit_document` without first navigating the preview browser to the doc. The user expects to watch every edit land in real time. Write-tool responses include `previewUrl` (when resolvable) and a `warning` when no client is currently attached to the doc.

**No screenshots after edits.** Do NOT take `preview_screenshot` after every `edit_document` / `write_document`. Trust the CRDT tool response as confirmation the edit landed. Only screenshot when debugging a visual issue or when explicitly asked.

**Linking.** Link liberally with `[[wiki-links]]` — every noun-phrase naming another document should be a link; redlinks are fine and signal "this should exist." Backlink density is how this knowledge base stays navigable for the next agent.

- **What goes in the brackets:** the target's **docName** — folder path + filename without `.md` / `.mdx` (e.g. the file `guides/auth-setup.md` is linked as `[[guides/auth-setup]]`). NOT the human-readable title, NOT `title:` frontmatter, NOT `aliases:`. Wiki-links are absolute from the content root, never relative — `[[foo]]` means root-level `foo.md`, never `guides/foo.md` from inside `guides/`. Cross-folder links always need the full path.
- **Display text different from the key:** `[[guides/auth-setup|Auth Setup]]` — pipe separator, target on the left, rendered label on the right. Anchors work the same way: `[[guides/auth-setup#quickstart]]`, or combined: `[[guides/auth-setup#quickstart|see the quickstart]]`.
- **Verify before walking away:** after writing a doc, call `get_dead_links({ sourceDocNames: ['your/doc/name'] })` — every unresolved bracket-target in that doc is listed. Fix or accept the redlinks deliberately. The editor's red-underline visual tolerates a slug fallback (`[[Auth Setup]]` may look resolved if `auth-setup.md` exists at root), but the backlink graph is strict-exact — trust `get_dead_links`, not the visual.

**Organize by folders, not hub files.** Folders are the organizational unit — group related docs in a shared folder and let the directory listing do the cataloging. Per-folder metadata (title, description, tags) lives in `.open-knowledge/config.yml` under the `folders:` key (glob `match:` + frontmatter defaults that merge with each file's own frontmatter at read time). Don't maintain an `INDEX.md` / `README.md` hub file inside a folder solely to catalog its children — `exec("ls <folder>")` returns the same view live, with per-file frontmatter + backlink counts.

**Server must be running.** If `write_document` or `edit_document` returns a "Hocuspocus server is not running" error, start it with `open-knowledge start` (via Bash) and retry. NEVER fall back to native `Edit` / `Write` for in-scope markdown — always use the MCP write tools so edits go through the CRDT layer with proper attribution.

**Non-markdown files.** Use native `Read` / `Edit` / `Grep` / `Bash` for source code, configs, and anything outside the path contract in `config.yml`: under `content.dir`, matching `content.include`, not removed by `content.exclude` or `.gitignore`.
<!-- open-knowledge:end -->

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

