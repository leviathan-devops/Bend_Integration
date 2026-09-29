# Jev_Gates x Bend 2 -- THE PROOFS. The machine owns this file. Each law
# in LAWS.bend is proven by a def of the same name (Laws.<law>).
#
# Shape of the proofs: structural induction everywhere. The equality
# verdict eq_case is threaded as a parameter the proof branches on (as in
# demos/proof_insertion_sort: a computed value cannot be matched in
# place); Subseq obligations are discharged by constructing Or evidence
# (skip ys's head, or match it and carry EQ + the tail's proof).

import Base
import ./main.bend as Jev
import ./LAWS.bend as Laws

# --------------------------------- helpers --------------------------

# EQ(x, x) always holds: induction on x.
def eq_refl(x: Nat) -> Jev.EQ(x, x):
  match x:
    case 0n:
      Unit{}
    case 1n+p:
      eq_refl(p)

# Subseq is reflexive: delete nothing.
def subseq_refl(xs: List<&2, Nat>) -> Jev.Subseq(xs, xs):
  match xs:
    case Nil{}:
      Unit{}
    case h <> t:
      Inr{(eq_refl(h), subseq_refl(t))}

# Dropping the head of h <> xs leaves a subsequence of h <> xs.
def subseq_drop1(h: Nat, xs: List<&2, Nat>) -> Jev.Subseq(xs, h <> xs):
  match xs:
    case Nil{}:
      Unit{}
    case k <> u:
      Inl{subseq_refl(k <> u)}

# consume never adds: its result is a subsequence of its input.
def consume_subseq.fin(+a: Nat, h: Nat, t: List<&2, Nat>, rec: Jev.Subseq(Jev.consume(a, t), t), c: Or(Jev.EQ(a, h), Jev.NE(a, h)))
  -> Jev.Subseq(Jev.consume_dec(a, h, t, Jev.consume(a, t), c), h <> t):
  match c:
    case Inl{e}:
      subseq_drop1(h, t)
    case Inr{e}:
      Inr{(eq_refl(h), rec)}

def consume_subseq(+a: Nat, +xs: List<&2, Nat>) -> Jev.Subseq(Jev.consume(a, xs), xs):
  match xs:
    case Nil{}:
      Unit{}
    case h <> t:
      consume_subseq.fin(a, h, t, consume_subseq(a, t), Jev.eq_case(a, h))

# ---------------------------------- laws ----------------------------

def Laws.judge_shrinks(t, a):
  match t:
    case Jev.Ticket{acts, live}:
      match live:
        case True{}:
          consume_subseq(a, acts)
        case False{}:
          Unit{}

def Laws.judge_binds(t, a, b):
  Laws.judge_shrinks(Jev.judge(t, a), b)

def Laws.closed_shrinks(t, a):
  Unit{}

def Laws.consume_removes():
  {==}

def Laws.has_keeps():
  {==}

# ── the companion proofs (both compute; no new machinery) ────────────────────────
def Laws.judge_keeps_sibling():
  {==}

def Laws.judge_drops_judged():
  {==}
