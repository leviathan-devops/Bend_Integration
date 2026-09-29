# Jev_Gates x Bend 2 -- v1 proof-gate integration demo

A live, tested integration of **Bend 2's proof gate** into a real project:
`Jev_Gates` (this workspace's ticket-enforcement system). The model in
`main.bend` is a Bend 2 port of the core ticket semantics described in
`../docs/TICKET_ARCHITECTURE_v2.md`: a ticket carries the acts it still
authorizes (a multiset of act ids) plus a live flag; `judge(t, a)` spends one
authorization of act `a`; a closed ticket authorizes nothing.

The point is not the model -- it is the **gate**: invariants are stated in
`LAWS.bend` (operator-owned), proven in `PROOF.bend` (machine-owned), and a
code change that violates a law **cannot pass** `bend PROOF.bend`.

## The three-file contract

- `main.bend` -- the model + a runtime trace. Anyone may edit.
- `LAWS.bend` -- the laws. **Operator-owned.** The machine never edits it to
  make a proof pass. SEVEN laws: judge_shrinks (judging only spends
  authorizations), judge_binds (re-judging grants nothing), closed_shrinks (a
  closed ticket never grows), consume_removes + has_keeps (concrete
  regression pins on consume/has), and -- added 2026-09-29 -- the two COMPANION
  laws judge_keeps_sibling + judge_drops_judged.

  ★ WHY THE COMPANIONS EXIST (a measured defect, now fixed). The first five laws
  are all LOWER bounds -- "nothing is GAINED". A `judge` that discards the entire
  authorization set satisfies every one of them, because `Subseq(Nil, ys)` is
  `Unit` by construction. That is not a theory: the destructive kernel was run
  against the unchanged law set and printed **ALL PROOFS CHECK** -- including
  through `--verdict`, the Lean-proven kernel. The Lean kernel was doing its job;
  the LAWS were too weak, and nothing in the trust stack can catch that (Bend's
  own N5: the `.bendtt` translation has no proof; a human must confirm what a law
  STATES). `mutation-check/` holds that destructive kernel as a standing NEGATIVE
  CONTROL -- `sh mutation-check/check.sh` requires the real kernel to PASS and the
  mutant to be REFUSED. The pattern is Bend's own `demos/proof_insertion_sort`:
  `sort_sorted` alone is satisfied by returning `[]`; `sort_perm` pins it.
- `PROOF.bend` -- the proofs, one `def Laws.<law>` per law. The machine owns
  it. Proofs that cannot close print `SOME PROOFS FAIL` and block.

The gate has no override: there is no flag to skip, no annotation to lie to.
The only ways out are fixing the model, fixing the proof, or the operator
changing `LAWS.bend` and re-proving.

## Quick start

Requirements: bend 2.0.x at `~/.bend` (official `install.sh`), `elan` + Lean
v4.34.0 for `--verdict`, clang >= 14 for the native build.

    sh run_demo.sh                # the full battery, one command (chmod +x is host-blocked; sh works)

Manual equivalent:

    export PATH="$HOME/.bend/bin:$HOME/.elan/bin:$PATH"
    export BEND_NO_TELEMETRY=1
    bend PROOF.bend               # fast checker  -> ALL PROOFS CHECK
    bend PROOF.bend --verdict     # proven BendTT kernel (Lean) -> ~25s
    bend main.bend                # runtime trace of the ticket kernel
    bend main.bend -o jev-demo    # native binary; ./jev-demo --threads 8

## How it is designed to be used in a project

1. **State laws from invariants you already document.** The five laws here
   are distilled from documented Jev_Gates properties (spend-only ticket
   semantics) plus two executable pins on `consume`/`has`. Start with one
   structural law and two pins.
2. **Every change cycle: edit model -> run the gate.** Machine edits to
   `main.bend` or `PROOF.bend` are only accepted when the gate prints
   `ALL PROOFS CHECK`; the run/verdict pair distinguishes "fast but
   untrusted" from "mathematically valid" (see EVIDENCE.md).
3. **Wire it into CI as a required check:**
   `bend PROOF.bend --verdict` must exit 0. The runtime output of
   `main.bend` is for eyeballing only -- the verdict is the evidence.
4. **Give agents the rule sheet.** Paste `AGENTS.md.snippet` into the
   project's AGENTS.md so any agent working the tree knows: never touch
   `LAWS.bend`, never weaken a proof, gate output is the only evidence.
5. **Failure path.** `SOME PROOFS FAIL` names the exact location (file:line)
   and the unprovable obligation. Fix the model or the proof. If the LAW is
   genuinely wrong, the operator edits `LAWS.bend` -- and the proofs must be
   updated until green again.

## What was exercised for real (host: this machine)

- bend 2.0.32, Lean v4.34.0 via elan, clang 18, RTX 4080 (CPU path).
- `bend PROOF.bend` -> **ALL PROOFS CHECK** (5/5 laws).
- `bend PROOF.bend --verdict` -> **ALL PROOFS CHECK** in 25.0s (Lean kernel).
- `bend main.bend` -> correct trace: acts 1,2,3 spent (ALLOW), everything
  else DENY, budget ends `[]`; close+judge -> `[]`.
- Native build -> `jev-demo` (1.1 MB), identical trace, `--threads 8` OK.
- **Adversarial A (model mutation):** one line changed in `consume_dec`'s
  deny path to mint the act (`h <> rec` -> `a <> h <> rec`) -> runtime budget
  explodes into garbage; `bend PROOF.bend` -> `SOME PROOFS FAIL` at
  `consume_subseq.fin` (`expected: Jev.EQ(a, h) / observed: Jev.EQ(h, h)`).
  Restored -> green.
- **Adversarial B (false law):** `consume_removes` claim flipped to
  `== True{}` -> `SOME PROOFS FAIL` (`expected: False{} / observed: True{}`).
  Restored -> green.

Full transcripts: `EVIDENCE.md`.

## What this does and does not guarantee

- The fast checker is deliberately untrusted (its own docs say use
  `--verdict` for mathematical validity); `--verdict` re-checks through the
  proven BendTT kernel. Use `--verdict` as the CI-grade check.
- This is a v1 **semantic model** of the ticket kernel, parallel to -- not
  replacing -- the TypeScript implementation and its jest battery. It adds
  the invariant gate the TS tests cannot give: proof-backed rejection.
- Bend 2 is young tooling; the language has strict rules (binder-order
  matching, no computed scrutinees, termination must be a direct structural
  decrease, forward references banned). The proof idioms that survived are
  documented in the file comments -- reuse them.
- GPU `!` parallelism needs clang 19 + CUDA 12; this host ran the CPU path.

## Files

- `main.bend` (185 lines) -- EQ/NE/eq_case evidence kit, Ticket, consume,
  judge, has, Subseq, runtime trace.
- `LAWS.bend` (43 lines) -- the 5 laws, operator-owned.
- `PROOF.bend` (77 lines) -- the proofs, machine-owned.
- `run_demo.sh` -- the battery above.
- `AGENTS.md.snippet` -- paste into a project's AGENTS.md.
- `EVIDENCE.md` -- verbatim transcripts of every run.
- `mutation-check/` -- the must-fail mutant + `check.sh`, the negative control.
  A firewall without a FAILING case is theater.

## Porting to another project

1. Copy the three files; keep the section layout (equality evidence ->
   data -> operations -> relation -> laws -> proofs).
2. Write 1 structural law + 2 pins in `LAWS.bend` for the invariant that
   matters (the one whose violation is currently caught only by a human
   reviewer, if ever).
3. Prove it in `PROOF.bend`. Proof patterns that worked here: equality-as-
   evidence threaded as a parameter (`consume_dec`), recursion threaded as
   `rec` to dodge forward references (`has_step`), shrink relations as
   recursive Types (`Subseq`), reflexive proofs by induction.
4. Add the gate to CI; paste the snippet into AGENTS.md; never let the
   machine edit the laws.

_Warts to expect on first contact: `match` cannot scrutinize a computed
value (thread the verdict), a match on a later parameter locks earlier ones
(match in binder order), recursive calls must decrease left-to-right (put
the shrinking argument first), and defs cannot forward-reference (order or
thread). Each cost one compile cycle in building this demo; all are in the
file comments where they bit._
