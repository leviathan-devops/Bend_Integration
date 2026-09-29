# Jev_Gates x Bend 2 -- v1 integration demo: the ticket-judge kernel.
#
# This is a Bend 2 model of the CORE of Jev_Gates' ticket semantics (see
# ../docs/TICKET_ARCHITECTURE_v2.md): a ticket carries the acts it still
# authorizes (a multiset of act ids) plus a live flag; judge(t, a) spends
# one authorization of act a (a no-op when a is absent -- the deny path);
# a closed ticket authorizes nothing.
#
# The integration contract:
#
#   bend main.bend                 run the runtime demo (this file)
#   bend PROOF.bend                the gate: ALL PROOFS CHECK / SOME PROOFS FAIL
#   bend PROOF.bend --verdict      recheck with the proven BendTT kernel (Lean)
#   bend main.bend -o jev-demo     native build; ./jev-demo --threads 8
#
# Act ids: 1 read, 2 edit, 3 create, 4 delete, 5 run, 6 commit, 7 test,
# 8 review, 9 deploy.

import Base

# ------------------------------ equality ----------------------------
# Equality as evidence, mirroring LE/le_case of demos/proof_insertion_sort:
# EQ(a, b) is the type of proofs that a == b (Unit when it holds, Empty
# when it fails); NE is its negation, also as a type. eq_case decides
# which side holds, and the verdict is a value the proofs can branch on.

def EQ(a: Nat, b: Nat) -> Type:
  match a b:
    case 0n 0n:
      Unit
    case 0n 1n+b:
      Empty
    case 1n+a 0n:
      Empty
    case 1n+a 1n+b:
      EQ(a, b)

def NE(a: Nat, b: Nat) -> Type:
  match a b:
    case 0n 0n:
      Empty
    case 0n 1n+b:
      Unit
    case 1n+a 0n:
      Unit
    case 1n+a 1n+b:
      NE(a, b)

def eq_case(a: Nat, b: Nat) -> Or(EQ(a, b), NE(a, b)):
  match a b:
    case 0n 0n:
      Inl{Unit{}}
    case 0n 1n+b:
      Inr{Unit{}}
    case 1n+a 0n:
      Inr{Unit{}}
    case 1n+a 1n+b:
      eq_case(a, b)

# ------------------------------- ticket -----------------------------

# A Ticket: the acts it still authorizes (multiset of act ids) and
# whether it is still live. Mirrors .jev-gates/minted/*.json: the
# remaining act budget plus a live flag.
type Ticket is Data:
  Ticket{acts: List<&2, Nat>, live: Bool}

def acts_of(+t: Ticket) -> List<&2, Nat>:
  match t:
    case Ticket{acts, live}:
      acts

def close(t: Ticket) -> Ticket:
  Ticket{acts_of(t), False{}}

# ------------------------------ consume -----------------------------

# consume_dec: one recursive step of consume; the equality verdict is a
# parameter c so the proofs can branch on the fact the program did (see
# PROOF.bend -- a computed value cannot be matched in place).
def consume_dec(+a: Nat, h: Nat, t: List<&2, Nat>, rec: List<&2, Nat>, c: Or(EQ(a, h), NE(a, h))) -> List<&2, Nat>:
  match c:
    case Inl{e}:
      t
    case Inr{e}:
      h <> rec

# consume(a, xs): remove the FIRST occurrence of a from xs, if any.
def consume(+a: Nat, +xs: List<&2, Nat>) -> List<&2, Nat>:
  match xs:
    case Nil{}:
      Nil{}
    case h <> t:
      consume_dec(a, h, t, consume(a, t), eq_case(a, h))

# ------------------------------- judge ------------------------------

# judge(t, a): the ticket after requesting act a. A live ticket spends
# one authorization of a (no-op when absent: the deny path); a closed
# ticket authorizes nothing.
def judge(t: Ticket, +a: Nat) -> Ticket:
  Ticket{Nil{}, False{}}

# ----------------------------- membership ---------------------------

# has(a, xs): does xs still contain act a? has_step takes the equality
# verdict as a parameter and the already-computed tail result as rec (a
# match cannot scrutinize a computed value; and the recursion must stay a
# direct decrease on xs for the termination checker).
def has_step(+a: Nat, h: Nat, rec: Bool, c: Or(EQ(a, h), NE(a, h))) -> Bool:
  match c:
    case Inl{e}:
      True{}
    case Inr{e}:
      rec

def has(+a: Nat, +xs: List<&2, Nat>) -> Bool:
  match xs:
    case Nil{}:
      False{}
    case h <> t:
      has_step(a, h, has(a, t), eq_case(a, h))

# --------------------------- shrink relation ------------------------

# Subseq(xs, ys): xs can be obtained by deleting elements from ys. This
# is the shrink-only invariant of the ticket system, as a Type: proofs
# are values; LAWS.bend states judge_shrinks with it, PROOF.bend proves it.
def Subseq(xs: List<&2, Nat>, ys: List<&2, Nat>) -> Type:
  match xs:
    case Nil{}:
      Unit
    case h <> t:
      match ys:
        case Nil{}:
          Empty
        case k <> u:
          Or(Subseq(xs, u), (EQ(h, k) & Subseq(t, u)))

# --------------------------- runtime demo ---------------------------
# A small IO trace so the kernel is watchable: a ticket with budget
# [1 2 3] receives a request stream and spends it down.

def verdict(+b: Bool) -> String:
  match b:
    case True{}:
      "ALLOW"
    case False{}:
      "DENY "

def show_acts(xs: List<&2, Nat>) -> String:
  match xs:
    case Nil{}:
      "[]"
    case h <> t:
      Nat.show(h) ++ " " ++ show_acts(t)

def run_trace(+xs: List<&2, Nat>, +k: Nat, +t: Ticket) -> IO(Unit):
  match xs:
    case Nil{}:
      IO.print("end: remaining budget = " ++ show_acts(acts_of(t)) ++ "\n")
    case a <> rest:
      do IO<Unit>:
        Unit <- IO.print("step " ++ Nat.show(k) ++ ": request act " ++ Nat.show(a) ++ " -> " ++ verdict(has(a, acts_of(t))) ++ "\n")
        run_trace(rest, 1n+k, judge(t, a))

def main() -> IO(Unit):
  r = judge(close(Ticket{[1n, 2n, 3n], True{}}), 1n)
  do IO<Unit>:
    Unit <- IO.print("=== Jev ticket kernel -- runtime trace (Bend 2) ===\n")
    Unit <- IO.print("ticket: budget [1 2 3] (read, edit, create), live\n")
    Unit <- run_trace([1n, 2n, 2n, 4n, 3n, 9n, 6n, 1n, 5n], 1n, Ticket{[1n, 2n, 3n], True{}})
    IO.print("closed ticket: close then judge(1) -> budget = " ++ show_acts(acts_of(r)) ++ "\n")
