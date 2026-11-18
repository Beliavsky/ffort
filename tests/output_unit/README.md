# ISO_FORTRAN_ENV OUTPUT_UNIT

This suite preserves the user's exact four-line anonymous main program in
`cases/exact_user_multiline.f90`. Certified 0.45 rejects it at 1:20 with
`USE requires a module defined earlier in this source`. The fixed implementation
prints the actual host stdout unit, 6 on the verified GNU 14.2 processor. The
semicolon variant is a separate regression, not a replacement of that source.

Run:

    python3 tests/output_unit/test_runner.py
    python3 tests/output_unit/run_tests.py --candidate /path/to/app --gfortran /path/to/gfortran

The generator reproduces all source bytes, source identities and manifest from
`generate_cases.py` and the separately recorded `diagnostics.json`. It does not
learn expected results from the candidate. Source hashes are independently pinned
in `SOURCE-IDENTITY.json`. The 38 cases comprise 23 strict GNU executions, 12 GNU
compile-only subset/runtime boundaries, and 3 standard-invalid GNU rejections.
The latter are never counted as execution agreement. Runtime-error GNU programs
are deliberately not executed. The producer's existing PURE diagnostic uses an
exact pinned 0:0 location and full message, rather than an invented source location.

Formatted CHARACTER records, significant blanks, newlines and pending-output
prefixes are byte-exact. Only three list-directed integer outputs use opt-in exact
Decimal/integer token comparison; no float conversion, tolerance or text folding.
Successful `--check` must be completely silent. Static failures must match both
check/run status, exact path/location/message and empty stdout. Runtime failures
must preserve the exact previously committed prefix and publish no failed item.
Crashes, backtraces, timeouts, compiler ICEs and nonfinite numbers are rejected.
Candidate identity is checked before and after execution. 33 adversarial self-tests
cover these rules and exact generation/source reproduction.

Independent native programs cover 311 IR/parser/adapter/runtime assertions and
44 strict producer assertions. The former includes unused-import corruption,
constant/KIND evaluation, retained WRITE unit identity, all forbidden instruction
fields, wrong remote imports, wrong values and module-nature forgery. Erasing a
unit identity to `*` remains safe at runtime but is explicitly rejected by source
verification. The producer test retains exact nature, ONLY/rename and named UNIT
metadata without changing vendor code.

The successful alias names are ordinary identifiers such as `u` and `stdout`.
Three preserved `out` aliases remain explicit compile-only subset boundaries
because OUT is reserved by the existing parser. No source is rewritten to hide
that pre-existing limitation. See `../../docs/OUTPUT-UNIT.md` for the full contract.
