#!/bin/sh
# The negative control: the REAL kernel must pass; the MUTANT must be REFUSED.
export PATH="$HOME/.bend/bin:$HOME/.elan/bin:$PATH"; export BEND_NO_TELEMETRY=1
cd "$(dirname "$0")/.." || exit 1
FAILED=0
echo "== 1/2 the REAL kernel must PASS =="
bend PROOF.bend && echo "PASS (as required)" || { echo "FAIL (the real kernel must pass)"; FAILED=1; }
echo
echo "== 2/2 the MUTANT must be REFUSED =="
if bend mutation-check/PROOF_mutant.bend; then
  echo "FAIL — the mutant was ACCEPTED. The law set is vacuity-satisfiable again."
  FAILED=1
else
  echo "PASS (the mutant was refused, as required)"
fi
echo
[ "$FAILED" -eq 0 ] && echo "NEGATIVE CONTROL: OK" || echo "NEGATIVE CONTROL: BROKEN"
exit $FAILED
