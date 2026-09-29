# EVIDENCE -- Jev_Gates x Bend 2 v1 demo (verbatim run transcripts)

Host: this workstation. Date: 2026-09-28. Toolchain: bend 2.0.32
(`~/.bend/bin`), Lean v4.34.0 (elan, `~/.elan/bin`), clang 18, RTX 4080 12GB
(CPU path used). All commands run from
`JARVIS_WORKSPACE/Shared_Workspace/Jev_Gates/bend-integration/` with
`BEND_NO_TELEMETRY=1`.

## RUN 1 -- fast checker, all laws proven (exit 0)

    $ bend PROOF.bend
    ALL PROOFS CHECK
    Use --verdict for mathematical validity.
    GATE_EXIT=0

## RUN 2 -- proven kernel, verdict-grade (exit 0, 25.0s)

    $ time bend PROOF.bend --verdict
    ALL PROOFS CHECK

    real    0m25.011s
    user    0m40.156s
    sys     0m1.318s
    VERDICT_EXIT=0

## RUN 3 -- runtime trace, correct spend-only semantics (exit 0)

    $ bend main.bend
    === Jev ticket kernel -- runtime trace (Bend 2) ===

    ticket: budget [1 2 3] (read, edit, create), live

    step 1: request act 1 -> ALLOW
    step 2: request act 2 -> ALLOW
    step 3: request act 2 -> DENY
    step 4: request act 4 -> DENY
    step 5: request act 3 -> ALLOW
    step 6: request act 9 -> DENY
    step 7: request act 6 -> DENY
    step 8: request act 1 -> DENY
    step 9: request act 5 -> DENY

    end: remaining budget = []

    closed ticket: close then judge(1) -> budget = []

    RUNTIME_EXIT=0

(Each second 2 is denied after the first was spent; every act not in the
original budget is denied; close+judge yields the empty budget.)

## RUN 4a -- ADVERSARIAL: model mutation (mint-on-deny), runtime

Patch applied to `main.bend :: consume_dec` deny path:

    -      h <> rec
    +      a <> h <> rec

Runtime: the invariant breaks visibly -- the budget GROWS (denied acts get
minted at every step; here act 5 arrives first in the trace after mutation,
so the exploded multiset is 5-prefixed):

    $ bend main.bend
    ...
    end: remaining budget = 5 1 5 6 5 9 5 1 5 6 5 3 ... (grows without bound per request)
    RUNTIME_EXIT=0

## RUN 4b -- ADVERSARIAL: same mutation, THE GATE REFUSES (exit 1)

    $ bend PROOF.bend
    SOME PROOFS FAIL
    Error:
    - expected : Jev.EQ(a, h)
    - observed : Jev.EQ(h, h)
    Context:
    - a   : Nat
    - h   : Nat
    - t   : List<&2, Nat>
    - rec : Jev.Subseq(Jev.consume(a, t), t)
    - e   : Jev.NE(a, h)
    Location: consume_subseq.fin
    46 |     case Inr{e}:
    47>|       Inr{(eq_refl(h), rec)}
       |            ^^^^^^^^^^
    48 |
    GATE_EXIT=1

The proof obligation `Subseq(consume(a, xs), xs)` no longer closes: the
mutated model inserts `a` where the proof must show `a` was already there.
The gate names file, line, and the unprovable equality. Restore -> RUN 5.

## RUN 5 -- ADVERSARIAL: false law, refused (exit 1)

LAWS.bend `consume_removes` claim flipped `== False{}` -> `== True{}`:

    $ bend PROOF.bend
    SOME PROOFS FAIL
    Error:
    - expected : False{}
    - observed : True{}
    Location: Laws.consume_removes
    73 | def Laws.consume_removes():
    74>|   {==}
       |   ^^^^
    75 |
    GATE_EXIT=1

A wrong law cannot be "proved" -- `{==}` refuses because evaluation gives
False. Restored -> RUN 6.

## RUN 6 -- FINAL full battery after restore (all exit 0)

    $ bend PROOF.bend
    ALL PROOFS CHECK
    Use --verdict for mathematical validity.
    GATE_EXIT=0

    $ bend PROOF.bend --verdict
    ALL PROOFS CHECK
    VERDICT_EXIT=0

    $ bend main.bend          # trace identical to RUN 3
    RUNTIME_EXIT=0

    $ bend main.bend -o jev-demo
    BUILD_EXIT=0
    -rwxrwx--x+ 1 leviathan leviathan 1119592 Sep 28 22:36 jev-demo
    $ ./jev-demo --threads 8  # trace identical to RUN 3
    NATIVE_EXIT=0

## Reading of the evidence

- Green: gate (fast) + gate (proven kernel) + runtime + native, twice
  (before and after the adversarial cycle).
- Refusals: model-level violation caught (`EQ(a,h)` vs `EQ(h,h)`), and
  law-level falsehood caught (`False{}` vs `True{}`). Both named exactly;
  neither had an override path.
- The two checkers disagree in trust (not in this verdict): the fast checker
  is untrusted by design; `--verdict` re-checks through the Lean-proven
  BendTT kernel. CI should require the `--verdict` line.
