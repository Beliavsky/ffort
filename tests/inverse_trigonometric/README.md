# Bounded real inverse trigonometric tests

This independent suite covers ASIN(X), ATAN(X), ATAN(Y,X), and ATAN2(Y,X)
for finite REAL(4)/REAL(8), ranks zero through three. Binary arguments have the
same kind and conforming nonscalar shapes; either argument may expand from a
scalar. ASIN accepts [-1,1]. Binary ATAN/ATAN2 reject the pair (zero,zero),
including every sign of zero. When only one argument is zero, its sign and the
quadrant are retained. Complex values, other real kinds, rank four, optional
KIND arguments, and malformed keyword/arity/type combinations are boundaries.

The merged release includes named formats. Run its active profile from this directory:

```
python3 test_runner.py
python3 run_tests.py --candidate /path/to/fortfront-interpreter --gfortran /path/to/gfortran --with-named-formats
```

There are 222 source cases: 173 GNU executions, 17 GNU compile-only boundaries,
and 32 GNU rejections. All source bytes are fixed by manifest hashes. The runner
snapshots the candidate, records its hash and version, enforces check/run exit
stages, checks diagnostics and stdout leaks, verifies source preservation before
and after execution, and rejects nonfinite oracle output. GNU-only and
candidate-only runs are supported. An independent candidate tree can supply
`--registry /path/to/intrinsic_registry.f90`; otherwise the local registry is
checked. ASIN, ATAN, and ATAN2 must each have exactly one registry identity; all
names must be unique and the declared registry size must equal its entries.

The 22 runner self-tests verify adjacent decimal and wide-integer distinctions,
subnormal preservation, signed zero, explicit tolerance, stage failures,
diagnostics, leaked output, exact formatted output, and registry invariants.
Decimal comparisons are exact by default. Real math cases explicitly permit
relative error of 3e-7 for binary32 or 4e-15 for binary64 to accommodate
independently compiled host math and list-directed decimal output. There is no
absolute tolerance floor. Zero signs are always exact, including under relative
tolerance; subnormal values cannot be replaced by zero. No tolerant fallback is
applied to the byte-exact formatted upstream demo_sin output.

The unchanged complete upstream demo_sin and demo_asin are MIT-licensed
M_intrinsics programs at commit fc14233036d910e3678d350efc24609e11475067.
Their exact original source hashes and paths are in upstream.json, and the
complete original license is UPSTREAM-LICENSE. demo_sin is the primary
end-to-end acceptance case. demo_asin additionally needs the independent named
character format feature: the default profile requires its precise clean
rejection at `print all`; `--with-named-formats` instead requires GNU-equivalent
execution. The shipped aggregate verifier uses `--with-named-formats`; omit that switch only
when validating the isolated inverse-trigonometric feature. The selected profile
is recorded, and either profile enforces one
outcome rather than accepting success and failure interchangeably.

The native tests `test/test_inverse_trigonometric.f90` and
`test/test_inverse_trigonometric_producer.f90` add 3,173 runtime/public-IR
assertions and 35 producer cases. They cover literal and declaration cache
consistency; result/operand type, kind, rank, extent and dimensions; operand
count, masks, invalid IDs and cycles; second-operand corruption; empty arrays
and metadata-only KIND; both-kind nonfinite values in either argument; all four
signed-zero pair combinations; keyword result type/rank; and array, function,
and generic names that shadow the intrinsic. These are tests, not new core or
vendor implementation files.

Primary semantic references, checked 2026-11-15:

- https://gcc.gnu.org/onlinedocs/gfortran/ASIN.html
- https://gcc.gnu.org/onlinedocs/gfortran/ATAN.html
- https://gcc.gnu.org/onlinedocs/gfortran/ATAN2.html

In particular, the unary ATAN keyword is X, whereas the binary form uses Y,X.
The two-argument form is Fortran 2008 or later and agrees with ATAN2.

## Assignment-counter regression

The added 72 cases exercise whole-array assignment lengths 1 through 5 in both
real kinds for all four call forms, plus strided assignment, WHERE, FORALL and
repeated DO assignments with independent sentinels. The dedicated native test
`test/test_inverse_trig_assignments.f90` adds 160 assertions under both a small
2,000-step budget and the unchanged default budget. The three representative
old-binary failures are retained separately from corrected success evidence.
The numeric evaluator now declares its operand loop counter locally, rather
than modifying the enclosing interpreter frame's array-assignment counter.
