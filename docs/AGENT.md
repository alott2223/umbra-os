# Umbra Agent — an AI-native security control plane

Umbra Agent turns the offensive toolkit into **structured, scope-gated, audited
operations** that an AI agent can drive safely. It's the piece that makes Umbra an
*AI-native security workstation* rather than just a distro with tools on it.

> **For AUTHORIZED penetration testing, CTFs, security research and training
> only.** Every action is gated against an authorized-target scope and written to
> an append-only audit log — an agent (or you) **cannot** touch anything out of
> scope. Pair with `umbra panic` as the kill-switch.

## Why this makes an AI good at security work

Three design choices, each verified working:

1. **Structured tools, not scraped text.** `umbra agent nmap` runs nmap with XML
   output and returns **parsed JSON** — hosts, ports, services, banners as data.
   The agent reasons over structure instead of re-reading terminal dumps.
2. **A findings graph.** Every host, port, service, path, and vuln becomes a node
   with relationships (`host → has-port → port → runs → service`). The agent
   builds and queries a live engagement model, and `report` turns it into markdown.
3. **Enforced scope + audit.** `scope add` defines the authorized engagement;
   every tool call validates the target against it (IP-in-CIDR or domain-suffix)
   and logs the decision. Out-of-scope calls are **refused** — including over the
   API. This is what makes AI-driven offensive tooling *responsible*.

## CLI

```bash
umbra agent scope add 10.10.0.0/16        # authorize the THM lab subnet
umbra agent scope add scanme.nmap.org     # or a domain
umbra agent nmap 10.10.5.9                 # structured scan -> JSON + graph
umbra agent web http://10.10.5.9/         # fingerprint (headers, whatweb)
umbra agent dirscan http://10.10.5.9/     # content discovery (gobuster)
umbra agent nuclei http://10.10.5.9/      # templated vuln scan
umbra agent code ./myproject              # static-analyze a codebase (SAST)
umbra agent findings host                 # query the graph
umbra agent report                        # markdown engagement report
umbra agent audit                         # what has been done, to what
```

### Code auditing (the "programming / testing programs" half)

`umbra agent code <path>` statically analyses a codebase and files results into
the same graph. It uses **semgrep / gitleaks** if installed for depth, and always
runs a **stdlib heuristic pass** (zero dependencies) that flags hardcoded secrets,
AWS keys, private keys, `eval`/`exec`, `os.system`, `subprocess(shell=True)`,
`pickle.loads`, weak hashes, `verify=False`, unsafe `yaml.load`, and string-built
SQL — across Python/JS/TS/PHP/Ruby/Go/Java/shell/config files. Findings appear in
`umbra agent report` alongside the network results, severity-ranked.

An out-of-scope target is refused before the tool ever runs:

```
$ umbra agent nmap 8.8.8.8
REFUSED: 8.8.8.8 — target is NOT in the authorized scope
```

## API for AI agents (MCP + REST)

```bash
umbra agent serve            # http://127.0.0.1:7718  (localhost only)
```

Point any MCP client (Claude, Cursor, your own agent) at
`http://127.0.0.1:7718/mcp`. It exposes tools — `scope_add`, `nmap`, `web_probe`,
`dir_scan`, `findings`, `report` — with the **same scope enforcement and audit
logging** as the CLI. A plain REST surface is available too (`POST /nmap`, etc.),
plus `GET /health`.

The agent connects to **one endpoint**, authorizes its scope, scans, and the
results land as structured findings it can query and report on — every action
checked and logged.

## Design notes

- **Stdlib-only core** (Python): scope registry, findings graph, nmap XML parser,
  report, and the MCP/REST server all work with zero dependencies. External
  scanners (`nmap`, `whatweb`, `gobuster`, `nuclei`) are used *if installed* (they
  ship in the **[Red Team edition](REDTEAM.md)**) and degrade cleanly if not.
- Data lives in `~/.local/share/umbra/engagement.db` (0700); the audit trail is
  `~/.local/share/umbra/audit.log`.
- Complements the rest of the AI stack: **[`umbra ai`](../README.md)** drives GUI
  tools (Burp, Wireshark) and the desktop; **[`umbra assistant`](ASSISTANT.md)**
  provides persistent memory across engagements.

## Roadmap

- More structured parsers (ffuf, sqlmap, nuclei severity rollups, SMB/AD enum)
- Metasploit RPC as scoped tools; code-audit tools (semgrep/bandit) for the
  "programming/testing" half
- `umbra-fleet`: one isolated, snapshottable Umbra VM per agent/engagement
- Streaming events so agents react instead of polling
