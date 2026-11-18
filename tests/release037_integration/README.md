# Release 0.37 independent composition checks

This suite composes FRACTION, EXPONENT, SET_EXPONENT, IACHAR, SPACING,
NEAREST, finite-input GNU-extension ISNAN, and bounded RANDOM_NUMBER effects
inside ordinary impure functions. It supplements focused feature tests and
previous releases, without claiming support for either complete upstream library.

## Independent oracles

The 37 source cases have fixed integer, Boolean, text, and IEEE binary32/binary64
oracles. The four original-program numeric expectations were independently
calculated from binary rounding and mathematical model identities. No expected
answer was captured from the candidate or from GNU output.

GNU checks are explicitly separated:

- 18 safe executions, including two GNU-valid preserved subset boundaries.
- 12 compile-only probes covering undefined values, policy errors, metadata-only
  inquiries, and one GNU extreme-exponent discrepancy.
- Seven invalid sources that GNU must cleanly reject.

Every safe successful candidate execution must satisfy its independent oracle
and the GNU output comparison. Random sources print only guaranteed range,
shape, permutation, ordering, or exact probability-boundary properties. They
never compare candidate random values with GNU's different generator and never
rely on probabilistic uniqueness or on a draw being strictly greater than zero.
The shifted uniform range permits its rounded upper endpoint, while the raw
uniform draws retain the strict upper bound. The logical helper probability
inputs 0 and 2 deterministically produce false
and true, respectively, for every allowed uniform draw.

GNU 14.2 runtime SET_EXPONENT with I=-HUGE(0_8) returns nonzero values for
[1,-1], rather than the mathematically required signed underflow zeros. Only
this extreme INTEGER8 case is compile-only. The candidate still must satisfy
an independent signed-zero oracle. Integer narrowing is a possible explanation,
not a compiler-source finding. The standard-sized exponent and subnormal cases
remain strict differential checks. No GNU runtime-equivalence claim is made for
compile-only cases. A standalone source and observed -O0/-O2 evidence are
retained in `oracle-limitations/gnu14-receipt.json`.

Exact formatted records are compared byte-for-byte. The explicitly marked
numeric/mixed outputs use Decimal comparisons, exact integer tokens, a 2e-6
relative tolerance, and zero absolute tolerance. Zero cannot pass as a tiny or
least-subnormal value. Nonnumeric mixed tokens must match exactly; this mode is
not used as evidence for CHARACTER spacing. Every runtime-negative source must
emit exactly its completed `before` record, with no partial next record or extra
whitespace. Check-time failures must emit no stdout.

## Composition and preserved behavior

- Rank-two row gathering, duplicated indices, model decomposition/reconstruction,
  nearest neighbors, spacing, PARITY, COUNT, and ASCII array conversion.
- REAL32/REAL64 signed zeros, least subnormals, minimum normals, maximum finite
  values, mixed-kind nonzero directions too small for REAL32, and INTEGER8
  exponent extremes. Exact sign bits are additionally checked natively.
- Rank-three scalar expansion, empty shapes, OPTIONAL arguments, allocatable
  reassignment and parenthesized snapshots.
  Rank-three setup uses scalar/section assignments and SIZE(dim); reductions
  inspect rank-two sections. Existing rank-three RESHAPE/SUM/COUNT
  restrictions are not expanded by this suite.
- KIND suppresses value/shape evaluation for otherwise undefined, unallocated,
  invalid-domain arguments without permitting malformed expression metadata.
- Undefined values after an earlier valid array element; zero NEAREST direction;
  outward overflow; non-ASCII IACHAR; dynamic nonunit CHARACTER lengths;
  finite-only ISNAN policy; and exact record atomicity.
- PURE RNG rejection and unchanged ordinary-function I/O/module-write rejection.
  Native mutants independently preserve SIMPLE, result-identity and harvest
  validation restrictions.

ISNAN is a GNU extension, not a Fortran 2018 standard intrinsic. GNU invocations
add `-fall-intrinsics` only for sources using it or the exact original closure
that contains it. Finite inputs produce false. NaN/Infinity-producing arguments
and forged nonfinite native values remain rejected before predicate evaluation.
This does not exercise the original quick_sort early-return branch for NaNs or
claim general NaN/Infinity support.

## Exact original source preservation

`original/utility_module.f90` contains all original bytes, CRLF endings,
comments and continuation lines of these xutilities procedures:

- ran_uni_vec, lines 510–514
- runif_vec, lines 2651–2658
- random_logical_vec, lines 6192–6200
- random_logical_matrix, lines 6202–6210
- random_logical_3d, lines 6212–6220
- random_matrix, lines 7847–7851
- quick_sort, lines 8870–8942, including both nested procedures

Only the module wrapper, DP kind declaration and integration drivers are
synthetic. The six RNG helpers need no other dependencies. quick_sort includes
its complete quick_sort_1/interchange_sort closure, without an ISNAN substitute.
The original quick-sort code is exercised on empty/singleton arrays, duplicate
values, signed zeros/subnormals, known finite inputs, and random arrays large
enough to enter recursive partition sorting. Sorted results preserve the
original index permutation, not merely monotonic order.

Four full unchanged M_intrinsics programs (FRACTION, SET_EXPONENT, IACHAR,
SPACING) are also compiled/executed alongside that same original closure.
Their upstream commit is fc14233036d910e3678d350efc24609e11475067 and the
original MIT license is retained. The complete EXPONENT demonstration remains
outside this suite's supported scope because it also requires unrelated binary
formatting and IEEE/model inquiry features.

`original-source-map.json` records source/wrapper byte ranges, line ranges,
CRLF counts, sizes and SHA-256 values. The runner independently pins every body
and all four original programs, checks the complete closure and license, and
verifies provenance, fixture and candidate integrity before/after execution.
Changing a body or adding a replacement helper and forging the wrapper fingerprint
still fails verification: synthetic scaffolding is independently pinned too.

## Independent native public-IR evidence

`test/test_release037_composition.f90` mutates all seven new intrinsic families
inside a composed program and checks adapter validation separately from direct
execution. Source-free scalar roots for every family, and nested
ISNAN(SET_EXPONENT(FRACTION(...))) graphs, are built without parsing. Valid roots
are evaluated before any mutation. KIND must reject corrupted children even
though it suppresses value evaluation. Nonfinite inputs, signed-zero bits and
least subnormals are checked independently of the source driver.

Eleven RNG compositions compare equal-seed values and final stream states with
independent direct RANDOM_NUMBER controls using the candidate's public state
API: scalar broadcast, array-result preparation, separate call occurrences,
loops, SIZE execution, unevaluated KIND, empty arrays, scalar-versus-array
empty RHS behavior, default-root reset and
caller-owned state continuation. These comparisons do not use GNU's stream.
Failure probes check statement-atomic output and the precise rollback boundary:
an earlier completed draw remains, while nested draws evaluating a failed
RANDOM_NUMBER harvest are restored to that operation's entry state. This is not
a promise of whole-statement or whole-function transactional rollback.

## Reproduction

Use a completed immutable executable and explicit GNU compiler:

```sh
python3 tests/release037_integration/test_runner.py
python3 tests/release037_integration/run_tests.py \
  --candidate /absolute/path/to/fortfront-interpreter \
  --gfortran /absolute/path/to/gfortran
```

The runner snapshots and hashes the executable. GNU uses strict Fortran 2018,
`-pedantic-errors`, `-fcheck=all,no-array-temps`, and traps for invalid, divide by
zero and overflow. Only expected temporary-array warnings are disabled; all
other compile/runtime stderr is checked. Process timeouts, signals, host crashes,
missing diagnostics, warning leakage and exit-status substitution fail closed.

The generator recreates only this suite. Its isolated replay test requires
byte-identical cases, manifest, original bodies/programs, provenance and license.
The 50 harness self-tests cover provenance tampering, missing dependencies,
changed originals, candidate copy races, exact integer/text output, tiny versus
zero, nonfinite tokens, completed-record prefixes, crashes and timeouts.

## Final verification receipt

The immutable combined application passes all 37 source cases with zero
integrity failures. GNU passes all 37 staged checks; the harness passes 50
adversarial self-tests. The focused native target passes 1,328 assertions.
`receipt.json`, `combined-results.json`, `gnu-evidence.json`, and
`native-results.log` retain the results and exact artifact fingerprints.

Initial synthetic fixtures used forms outside the existing subset: a mixed
substring/ACHAR constructor whose lengths were not inferred, rank-three
RESHAPE/SUM/COUNT, rank-one vector subscripting in sort assertions, and
REAL(value,kind) in a native control. These were replaced with scalar/section
assignment, rank-two section reductions, scalar indexed checks, and DBLE. The
NEAREST negative test now checks its exact finite-range diagnostic. No core
restriction was relaxed, no original body changed, and no independent value,
state, shape, safety or atomicity assertion was removed.
