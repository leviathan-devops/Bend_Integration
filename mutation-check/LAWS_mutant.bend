# Jev_Gates x Bend 2 -- THE LAWS. The human owns this file: these are the
# invariants the operator relies on. PROOF.bend must prove each one, and
# `bend PROOF.bend` refuses ("SOME PROOFS FAIL") while any claim is open
# or false. The AI does not edit this file; it edits PROOF.bend and the
# code, and the gate decides.
#
# Law 1 judge_shrinks: judging only ever SPENDS act authorizations --
#   the judged ticket's set is a sub-multiset of the original.
# Law 2 judge_binds: BINDING -- re-judging an already-judged ticket
#   grants nothing beyond what the once-judged ticket had.
# Law 3 closed_shrinks: a closed ticket can never grow its set.
# Laws 4/5: concrete regressions on the consume/has path (executable
#   pins; a wrong consume shows up here first).

import Base
import ./main_mutant.bend as Jev

# LAW: act authorizations are only ever spent, never minted.
law judge_shrinks:
  for +t: Jev.Ticket
  for +a: Nat
  Jev.Subseq(Jev.acts_of(Jev.judge(t, a)), Jev.acts_of(t))

# LAW: binding -- no re-judging grants beyond the once-judged set.
law judge_binds:
  for +t: Jev.Ticket
  for +a: Nat
  for +b: Nat
  Jev.Subseq(Jev.acts_of(Jev.judge(Jev.judge(t, a), b)), Jev.acts_of(Jev.judge(t, a)))

# LAW: a closed ticket can never grow its set.
law closed_shrinks:
  for +t: Jev.Ticket
  for +a: Nat
  Jev.Subseq(Jev.acts_of(Jev.judge(Jev.close(t), a)), Jev.acts_of(t))

# LAW: consuming act 7 removes it (concrete pin).
law consume_removes:
  {Jev.has(7n, Jev.consume(7n, [7n, 8n])) == False{} : Bool}

# LAW: consuming act 7 keeps act 8 (concrete pin).
law has_keeps:
  {Jev.has(8n, Jev.consume(7n, [7n, 8n])) == True{} : Bool}

# ── ★ THE UPPER BOUND (2026-09-29) ───────────────────────────────────────────────
# Every law above is a LOWER bound: "nothing is GAINED". A judge that discards the
# entire authorization set satisfies all of them trivially — because
# Subseq(Nil, ys) is Unit by construction (see Subseq in main.bend).
# Proven mechanically: a destructive kernel + trivial proofs prints
# ALL PROOFS CHECK, and even `--verdict` (the Lean kernel) passes it.
# Lower bounds need their COMPANION, or the gate certifies a system that
# satisfies it by doing nothing. These two pin that judging act a removes
# exactly a and leaves its sibling alone. (The pattern is Bend's own
# demos/proof_insertion_sort: sort_sorted alone accepts []; sort_perm pins it.)

# LAW: judging act 7 leaves the sibling act 8 authorized.
law judge_keeps_sibling:
  {Jev.has(8n, Jev.acts_of(Jev.judge(Jev.Ticket{[7n, 8n], True{}}, 7n))) == True{} : Bool}

# LAW: judging act 7 removes act 7.
law judge_drops_judged:
  {Jev.has(7n, Jev.acts_of(Jev.judge(Jev.Ticket{[7n, 8n], True{}}, 7n))) == False{} : Bool}
