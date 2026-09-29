# THE BEND INTEGRATION — SANDBOXED

**The operator's order (2026-09-29, verbatim):** *"the bend integration needs to be
separate and sandboxed."*

**What this is:** the Bend-language integration experiments (the LAWS.bend law set, the
PROOF.bend proof harness, the mutation-check, the demo) — EXTRACTED from
`JARVIS_WORKSPACE/Shared_Workspace/Jev_Gates/bend-integration/` where a parallel session
authored them (commits ac354ab · e58ceb4 at Jev_Gates HEAD prior to the extraction).

**WHY separated:** the bend work has ZERO code coupling to Jev_Gates (no `bend` reference
in Jev_Gates' src/scripts/tests/package.json; its own `bend-integration/` root). Mixed
into the Jev_Gates tree it pollutes: the code-audit's diff scope (the gate reviewed 8 bend
files in a Jev_Gates review), the repo's identity, and the ship boundary. This directory
is its OWN project root — its own git history, its own README, no cross-references.

**THE PROVENANCE (the exact source state):**
- the source: `Jev_Gates/bend-integration/` @ the extraction (Jev_Gates HEAD e58ceb4)
- the source's tests: `mutation-check/check.sh` (the mutant-vs-real differential)
- the built binary `jev-demo` + the `.bak-*` files were DROPPED (build debris, not source)
- the Bend toolchain: `bend` (the HVM-family runtime — see README.md)

**THE SANDBOX LAWS:**
1. NO imports from or into Jev_Gates (or any other project) — this tree is self-contained.
2. Its OWN git repo (below) — a commit here never touches another project's history.
3. The build artifacts (the compiled `jev-demo`) are NOT tracked (rebuilt by run_demo.sh).
4. Any future coupling to Jev_Gates (or another project) lands as a NAMED cross-project
   dependency in a wrapper, never as a file copied into this tree.

**THE CONTENT:**
- `LAWS.bend` — the law set (the vacuity fix incl.)
- `PROOF.bend` — the proof harness
- `main.bend` — the demo program
- `mutation-check/` — the mutant/real differential (6 files: check.sh + the mutant pair)
- `EVIDENCE.md` / `README.md` — the record
- `AGENTS.md.snippet` — the doc fragment (kept from the source)
- `zone_probe.txt` — the probe output
