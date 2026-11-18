# Independent 0.47 cross-feature composition

This package is additive. It changes no library implementation, historical source,
or utility original. All 30 synthetic Fortran sources and 24 input files are
pinned by the generator, manifest and independent SOURCE-IDENTITY.json.

## Coverage and oracle boundaries

The 22 success sources combine derived-component defaults and constructor
overrides, repeated/recursive local lifetimes, INTENT(OUT), a nonempty function
result, external list input, BACKSPACE and endfile state, two independent input
units, MOVE_ALLOC ownership/bounds/CHARACTER lengths, recoverable ALLOCATE
STAT/ERRMSG, EOSHIFT rank-one/rank-two controls, rank-three input/transfer followed
by a rank-one section, empty arrays, NORM2, signed zero and T/TR/nonadvancing
records. They have deterministic independent expected output. Three runtime
safety cases cover invalid input without IOSTAT, unbound input and preserved
undefinedness after MOVE_ALLOC. Five additional compile-only cases retain reviewed source/expression boundaries.
None executes undefined Fortran under GNU.

GNU 14.2 uses `-std=f2018 -pedantic-errors -fcheck=all
-ffpe-trap=invalid,zero,overflow -O0`. All 30 sources compile silently; the 22
success sources execute silently on stderr and match their expected records.
The eight safety/subset sources are explicitly compile-only, not runtime agreement.
The first GNU run exposed a hand-derived TR expectation mistake: skipping over
retained column C does not blank it. Only that expected record was corrected;
its source and all other source bytes were retained. The source-located target
boundary column was also corrected by parser inspection before candidate use.
Both decisions are recorded in the work receipt, not hidden as feature changes.

## Preserved cross-feature boundaries and final preview

The first immutable preview run retained three failures, not regressions hidden
by source edits. EOSHIFT's existing metadata walker rejects direct derived-component
operands in BOUNDARY and in the SHIFT beneath KIND, with `invalid KIND argument
opcode`. External READ in an ordinary unprefixed function is also outside the
current effect subset. A separately attempted explicit IMPURE non-elemental
function reaches the existing prefix rejection. These four GNU-valid sources are
retained byte-for-byte with exact runtime/source rejection contracts. The two
EOSHIFT operand boundaries are runtime rejections, not claimed parser failures.
No claim is made that those language-valid programs are invalid Fortran.

Separately named positives stage component values into ordinary scalar controls,
and read in main before calling a nonempty default-result function. They exercise
the bounded supported paths without changing the original failed sources or
expanding implementation. Initial and intermediate failures, source hashes, the
scope review and final result are included in `oracle-evidence/`.

Final preview SHA-256
`c22c1d72e827434c65fb94b751d1b59a537e8aae50d0d271ad552f376acd70e9`
(version 0.47.0) passes all 30 outcomes, with 22 GNU executions and eight
explicitly compile-only references. Its hash is unchanged before/after. The exact
user source from `tests/derived_defaults/cases/exact_user.f90` also checks silently
and prints ` 1000.00000\n`, with unchanged source hash and version.

The two empty ordinary/PURE derived-result GNU disagreements remain in the
separate `tests/derived_defaults/oracle-evidence` package, with raw -O0/-O2 streams
and primary-standard rationale. They are not included in these 22 execution
agreements. The nonempty result composition is a distinct GNU-agreeing source.

## Input isolation and strict checks

The runner creates independent temporary directories for GNU and the candidate.
GNU receives pinned ordinary `fort.N` fixtures in its private directory, without
rewriting the source or adding OPEN statements. The interpreter receives different
pinned `input_N.dat` files through explicit `--input N=PATH` arguments. Its working
directory must not acquire native `fort.N` or any other unexpected file. All input
copies and original sources are checked for mutation. No stdin or outside file is
used. Input-unit and byte limits remain the existing caps.

Output is byte-exact, including CHARACTER padding, case, record endings and prior
nonadvancing text. Only designated entirely numeric records permit spelling
variation via exact finite Decimal equality, retaining signed zero and exact
INTEGER spelling. Tiny nonzero tokens cannot equal zero. No floating tolerance
is used. Check mode must be exactly silent; successful runs must have empty
stderr. Failures require exact source path, line, column, named diagnostic, exit
status and prior stdout. Crash, trace, timeout and compiler-ICE markers fail.
37 adversarial harness tests exercise these distinctions, source regeneration,
independent input identity, separate input copies and missing/modified/native files.

## Reproduction

```
python3 tests/release047_integration/test_runner.py
python3 tests/release047_integration/run_tests.py --gfortran /path/to/gfortran
python3 tests/release047_integration/run_tests.py --gfortran /path/to/gfortran --candidate /path/to/fortfront-interpreter
```

The candidate is hashed before and after the complete run. The source suite
never builds the interpreter or runs FPM. GNU-only preparation does not imply
candidate success; use the explicit candidate identity in the result JSON.
