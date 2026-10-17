# W1 evidence

Toolchain pinned to the version named in `EVIDENCE.md`: bend 2.0.32, Lean v4.34.0 for `--verdict`. `BEND_NO_TELEMETRY=1`. No process dialed the judge ports. Mocks bind port 0.

## Deterministic failure, watched red first

`sh run_demo.sh` before Lean was installed:

```
== 2/4 proven kernel: bend PROOF.bend --verdict ==
Error: the kernel did not build (lean: Executable not found in $PATH: "lean"); --verdict needs Lean v4.34.0 (elan toolchain leanprover/lean4:v4.34.0), or $BENDTT set to a built kernel
FAIL
== result ==
FAILURES PRESENT
```

The fast checker, the runtime trace, and the native build were already PASS in that same run. The fix is the toolchain the README already names, installed in CI. `LAWS.bend` was not edited.

After `elan` toolchain `leanprover/lean4:v4.34.0`:

```
== bend version ==
bend 2.0.32
PASS
== 1/4 fast checker ==
ALL PROOFS CHECK
PASS
== 2/4 proven kernel ==
ALL PROOFS CHECK
PASS
== 3/4 runtime demo ==
PASS
== 4/4 native build + run ==
PASS
== result ==
ALL GREEN
```

`sh mutation-check/check.sh` printed `NEGATIVE CONTROL: OK`. The mutant is refused at `Laws.judge_keeps_sibling` (`expected : False{}` / `observed : True{}`).

## Port guard, watched red first

The scanner stub returned no hits. `python3 -m unittest tests.test_port_guard -v` then failed the two planted cases and passed the mock and the clean-tree check:

```
test_mock_binds_port_zero_and_source_is_clean ... ok
test_planted_connection_is_refused ... FAIL
AssertionError: [] is not true : planted connection was not refused
test_planted_fixed_bind_is_refused ... FAIL
AssertionError: [] is not true : planted fixed bind was not refused
test_repo_tree_has_no_forbidden_connection ... ok
FAILED (failures=2)
```

After `scan` was implemented, the same four tests passed (`Ran 4 tests`, `OK`). Each test uses its own temp directory. The planted files are created there and are not part of the tree.

## Stale

`README.md` still says the fast checker proved 5/5 laws. `LAWS.bend` has seven laws, including the two companion laws dated 2026-09-29. Those seven pass on bend 2.0.32, including `--verdict`. The 2026-09-28 transcript in `EVIDENCE.md` predates the companions. The current Bend installer default is 2.0.37; this lane did not run that version.
