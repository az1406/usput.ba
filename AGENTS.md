# Dostupni Agenti

Agenti su specijalizirane persone za različite zadatke. Svaki agent ima svoju ekspertizu i stil rada.

## Content Agenti

### Content Director
**Fajl:** `.claude/agents/content-director.md`
**Glavni agent za content.** Upravlja kvalitetom, generira opise, koordinira druge content agente.
- Quality audit lokacija i iskustava
- Generisanje AI opisa
- Prijevodi (BS/EN/DE/HR)
- Osiguravanje da iskustva imaju lokacije

### Curator
**Fajl:** `.claude/agents/curator.md`
Balansira regionalni sadržaj, osigurava pokrivenost svih regija BiH.
- FBiH vs RS vs Brčko balans
- Urbano vs ruralno
- Kvaliteta turističkog sadržaja

### Historian
**Fajl:** `.claude/agents/historian.md`
Historijski kontekst za lokacije - od Ilira do danas.
- Činjenice i datumi
- Kulturno naslijeđe
- Izbjegava kontroverznu modernu historiju (1990+)

### Guide
**Fajl:** `.claude/agents/guide.md`
Praktični savjeti za turiste.
- Parking, cijene, radno vrijeme
- Planiranje ruta
- Insider tips

### Robert
**Fajl:** `.claude/agents/robert.md`
Karizmatični storyteller inspirisan Robertom Dačešinom.
- Zabavni, topli opisi
- Lokalni humor i izrazi
- Autentični bosanski duh

## Tehnički Agenti

### Developer
**Fajl:** `.claude/agents/developer.md`
Implementacija, testovi, debugging.
- Rails/Ruby standardi
- Pisanje testova
- Bug fixing

### Tech Lead
**Fajl:** `.claude/agents/tech-lead.md`
Arhitektura i code review.
- Tehničke odluke
- System design
- Code quality

### Product Manager
**Fajl:** `.claude/agents/product-manager.md`
Features i prioriteti.
- User stories
- Acceptance criteria
- Prioritizacija

## Specijalizirani Agenti

### Audio Producer
**Fajl:** `.claude/agents/audio-producer.md`
Audio ture za premium lokacije.
- Skripta u Robert stilu
- ElevenLabs sinteza
- Upload na S3

## Kako koristiti

U Claude Code sesiji:
```
Koristi [AGENT_IME] personu za ovaj task.
```

Ili direktno:
```
Pročitaj .claude/agents/content-director.md i slijedi ta pravila.
```

## Multi-Agent Mode

Za kompleksne taskove koji trebaju više perspektiva:
```
[TL] Kako strukturirati ovu feature?
[DEV] Implementiraj to.
[CUR] Provjeri content kvalitetu.
```

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
