# Umbra Bounty — a bug-bounty hunting workflow

`umbra bounty` makes Umbra a systematic assistant for **authorized** bug-bounty
programs. It encodes real methodology, keeps you inside scope, and produces the
kind of write-up mature programs actually accept — a proper PoC report, not
scanner output.

> Authorized programs only. Test strictly within a program's stated scope; the
> in-scope entries you register **gate `umbra agent`**, so anything outside the
> program is refused before a tool runs.

## The flow

```bash
# 1. Register the program and its scope (this seeds the scope gate)
umbra bounty program add airtable --url https://hackerone.com/airtable
umbra bounty program scope airtable staging.airtable.com in
umbra bounty program scope airtable airtable.com out
umbra bounty program reward airtable critical 5000
umbra bounty program reward airtable high 750
umbra bounty program show airtable

# 2. Work the playbook — a tracked web-app methodology, nothing skipped
umbra bounty checklist airtable                    # all categories
umbra bounty checklist airtable "access control"   # focus one
umbra bounty check 12 testing                       # mark an item in progress
umbra bounty check 12 found -n "IDOR on /v0 records"

# 3. Record findings (severity maps to the program's reward table)
umbra bounty finding add --program airtable \
  --title "IDOR: read another workspace's records via API" \
  --class "Broken Access Control" --severity high \
  --target "staging.airtable.com/v0/{baseId}" \
  --steps "Log in as A\nGET /v0/{baseId} with B's id\nRecords returned" \
  --impact "Any user reads bases they don't own, cross-workspace."

# 4. Generate a submission-ready report
umbra bounty report 1
```

## Why scope is wired to `umbra agent`

Registering `staging.airtable.com` as **in-scope** inserts it into the shared
scope registry. So when you (or an AI agent) run `umbra agent nmap airtable.com`,
it's **refused** — production and every out-of-scope host is off-limits by
construction, and every attempt is written to the audit log. Verified: adding
`staging.airtable.com` in-scope refuses `airtable.com`, `www.airtable.com`, and
everything else.

## The playbook (what gets seeded)

A structured web-app methodology, organized so nothing is missed:

- **Recon & mapping** — endpoints, tech stack, API style, client JS, roles
- **Authentication & session** — reset tokens, session handling, JWT, OAuth, MFA
- **Access control / authz** *(highest value)* — IDOR, horizontal/vertical
  privesc, tenant isolation, forced browsing, mass-assignment
- **Injection** — stored/reflected/DOM XSS, SQL/NoSQL, SSRF, SSTI, XXE
- **CSRF & client-side** — anti-CSRF, CORS, open redirect, clickjacking, postMessage
- **Business logic** — quota/credit abuse, races, workflow bypass
- **Files & disclosure** — upload abuse, sensitive data, verbose errors, secrets

Each item is tracked (`todo → testing → clear/found/na`) so an engagement has a
visible, auditable state.

## Realistic expectations

Mature programs (like Airtable) are well-picked-over: scanners are explicitly
rejected, the easy bugs are gone, and most sessions find nothing. The value here
is **systematic manual testing** — the tool keeps you organized, in scope, and
produces a clean report; the bug-finding is still patient human+AI work.

## Fits the rest of the stack

- **[`umbra agent`](AGENT.md)** — the scope-gated scanners + findings graph the
  bounty scope drives.
- **[`umbra assistant`](ASSISTANT.md)** — persistent memory across engagements.
- **`umbra ai`** — drives Burp/browser for the manual web testing.
