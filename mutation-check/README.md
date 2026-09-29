# THE NEGATIVE CONTROL — the mutant this law set exists to reject

A firewall without a FAILING case is theater (LASME). This directory holds the
must-fail mutant for the ticket laws: a `judge` that discards the entire
authorization set, plus proofs written the way the MACHINE would write them.

    judge(t, a) ≡ Ticket{Nil{}, False{}}

Run `sh check.sh`:

  - main.bend + LAWS.bend + PROOF.bend            → ALL PROOFS CHECK   (exit 0)
  - the mutant + the same laws + trivial proofs   → SOME PROOFS FAIL   (exit 1)

The mutant PASSES the pre-2026-09-29 law set — including through `--verdict`.
It FAILS the moment the companion laws (judge_keeps_sibling / judge_drops_judged)
are present, at Laws.judge_keeps_sibling, with expected: False{} / observed: True{}.
