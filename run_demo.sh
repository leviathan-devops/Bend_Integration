#!/bin/sh
# Jev_Gates x Bend 2 -- v1 integration demo: one-command run.
#
#   ./run_demo.sh          the full good-path battery
#
# Steps: version -> fast checker -> proven kernel (--verdict) -> runtime
# trace -> native build. Every step prints PASS/FAIL; the script exits
# non-zero if any step fails. The adversarial procedure (break the model,
# watch the gate refuse, restore) is documented in README.md; it was run
# for real and its transcripts are in EVIDENCE.md.
#
# Requirements: bend 2.0.x at ~/.bend (official install.sh), elan + Lean
# for --verdict, clang >= 14 for the native build.

cd "$(dirname "$0")" || exit 1
export PATH="$HOME/.bend/bin:$HOME/.elan/bin:$PATH"
export BEND_NO_TELEMETRY=1

FAILED=0
step()  { printf '\n== %s ==\n' "$1"; }
check() { if [ "$1" -eq 0 ]; then echo "PASS"; else echo "FAIL"; FAILED=1; fi; }

step "bend version"
bend version
check $?

step "1/4 fast checker: bend PROOF.bend"
bend PROOF.bend
check $?

step "2/4 proven kernel: bend PROOF.bend --verdict"
bend PROOF.bend --verdict
check $?

step "3/4 runtime demo: bend main.bend"
bend main.bend
check $?

step "4/4 native build + run: bend main.bend -o jev-demo  (then ./jev-demo)"
bend main.bend -o jev-demo && ./jev-demo
check $?

step "result"
if [ "$FAILED" -eq 0 ]; then echo "ALL GREEN"; else echo "FAILURES PRESENT"; fi
exit $FAILED
