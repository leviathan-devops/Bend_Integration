# Proofs for the MUTANT, written the way the machine would write them.
# Every inherited law is satisfied trivially; only the companion can object.
import Base
import ./main_mutant.bend as Jev
import ./LAWS_mutant.bend as Laws

def Laws.judge_shrinks(t, a):
  Unit{}

def Laws.judge_binds(t, a, b):
  Unit{}

def Laws.closed_shrinks(t, a):
  Unit{}

def Laws.consume_removes():
  {==}

def Laws.has_keeps():
  {==}

def Laws.judge_keeps_sibling():
  {==}

def Laws.judge_drops_judged():
  {==}
