# Umbra Assistant — a local, private AI with memory

Umbra ships a built-in AI assistant that runs **entirely on your machine**. No
cloud, no account, no telemetry — the same principle as the rest of the OS. It is
`stdlib`-only Python, so it works offline out of the box; optional accelerators
(a local LLM via **ollama**, transformer embeddings) are used only if present.

```
umbra assistant ask "how does umbra protect memory?"   # retrieval-augmented, local LLM
umbra assistant remember "Project X ships Friday" --project x --pin
umbra assistant recall "release date"                  # semantic + relationship search
umbra assistant index all                              # learn this machine
umbra assistant capsule save coding                    # snapshot your whole context
umbra assistant why 42                                 # why is this remembered?
umbra assistant serve                                  # REST + MCP API for other tools
```

Data lives in `~/.local/share/umbra/umbra.db` (dir mode `0700`). Nothing leaves
the device.

## What v1 does today

**Memory graph (not just vectors).** Memories are nodes in a SQLite graph with
typed **relationships** between them; recall combines keyword prefiltering,
semantic similarity, and **graph expansion** (neighbours of the best hits). Every
memory records provenance so `umbra assistant why <id>` can explain *why it's
kept* and *what it's linked to*.

**Importance & forgetting.** Each memory has an importance score blended from
explicit importance, recency, and use. `umbra assistant forget` prunes low-value,
stale, unused memories (dry-run by default; `--apply` to delete). Pinned memories
are never forgotten.

**Timeline & per-project spaces.** `timeline` shows what was learned when;
`--project` scopes everything, and file indexing auto-detects the project from the
nearest `.git`.

**Computer understanding.** `umbra assistant index fs|software|procs|all` builds
an on-device index of your files, installed software (`dpkg`), and running
processes — stored as memories the assistant can reason over.

**Context Capsules** *(signature feature).* `umbra assistant capsule save <name>`
snapshots your whole working context — cwd, git branch/HEAD/status, recently
changed files, open windows, and recent shell history. `capsule restore <name>`
brings it back weeks later so you resume instantly. Context restoration, not just
retrieval.

**Local LLM.** `umbra assistant ask` retrieves the most relevant memories, feeds
them to a local model via ollama, and stores the exchange (linked to the context
it used). No ollama? It degrades to a clean retrieval view. Set one up with
`umbra assistant llm setup`.

**Interfaces for everything.** A CLI, plus a **localhost-only** REST + **MCP**
server (`umbra assistant serve`, or `sudo umbra assistant api on`). Point Claude,
Cursor, or any MCP client at `http://127.0.0.1:7717/mcp` and they **share Umbra's
memory** — one brain across assistants. Config: `/etc/umbra/assistant-mcp.json`.

## Privacy posture

- On-device only; the API binds `127.0.0.1` and the systemd unit sets
  `IPAddressDeny=any` except localhost, `NoNewPrivileges`, `ProtectSystem=strict`.
- The LLM runtime and the API are **opt-in** (disabled by default) to keep the
  hardened attack surface small.
- Memories are local files under your home; combine with Umbra's `age` vault or a
  LUKS home for encryption at rest, and `umbra panic` wipes keys in an emergency.

## Roadmap (not in v1)

These are deliberately staged for later; v1 is the foundation they build on:

- Transformer/GPU embeddings, SIMD, incremental & background indexing, benchmarks
- Desktop apps: tray, command palette, **memory explorer**, timeline & relationship-graph views, live-indexing dashboard
- Distributed: multi-device & P2P sync, LAN discovery, conflict resolution, shared team memories
- Agent runtime: workflow engine, event triggers (e.g. *VS Code opens → load project context*), background autonomous jobs, plugin API
- More SDKs (Python/Rust/Go/TS), WebSocket API
- Experimental: "dream mode" idle reorganization, predictive context loading, semantic diff between knowledge versions, multi-model consensus search
- Encryption: hardware-backed (TPM) memory vault, air-gapped mode, self-destruct sessions

## How it fits Umbra

The assistant reuses the **AI-control layer** (`umbra ai`) — capsules capture open
windows through it, and an agent can both *see/act* on the desktop (`umbra ai`)
and *remember/reason* (`umbra assistant`). Together they make Umbra a machine an
AI can genuinely operate and learn on — privately.
