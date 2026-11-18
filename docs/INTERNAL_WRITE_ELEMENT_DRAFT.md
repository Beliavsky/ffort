> Historical preparation snapshot. Superseded by `INTERNAL_WRITE_ELEMENT.md`.
> Statements below describe the pre-build state and are retained as provenance.

# Whole CHARACTER element internal WRITE: unbuilt future draft

This isolated 0.50 draft is rebased onto certified FortFront 0.49 archive SHA-256
`ef1970fd7dc152229aafff59149c62886fb70a8de466b54b170003f45c594077`.
The four-file patch applied with zero offsets/fuzz. The only source difference
from the earlier preview was an unrelated LEADZ adapter correction. The draft
restores the old invalid scalar/PARAMETER/INTENT(IN) diagnostic wording so those
existing negative tests remain unchanged. No FortFront application or native
build has been run for this rebased draft.

## Intended bounded contract

Permit an internal WRITE unit that is one whole default-kind CHARACTER element
of a rank-one, rank-two or rank-three array. Subscripts must be scalar INTEGER
kind 4/8. Existing lower-bound, rank, extent, allocation, argument and character
length descriptors remain authoritative. Fixed arrays, automatic results and
supported allocatable/dummy arrays use their existing storage rules. Pointer,
PARAMETER and INTENT(IN) targets are rejected. Whole-array files, array sections,
vector-subscribed units, substrings and derived components are not added.
Existing scalar CHARACTER WRITE behavior remains separate.

The source guard retains a scalar element designator as the target, not an
expression to be evaluated for its old value. The adapter compares it against
the producer's existing unit-specifier expression AST and exact source binding.
No vendor producer delta is currently needed; reserved patch 0108 is unused.
The current producer's narrow PURE-local-file exemption is not broadened, so
explicit PURE array-element internal writes remain outside this draft's scope.

The runtime is designed to compute all subscripts once, check bounds/allocation
without requiring target definedness, freeze the logical target and length,
render the format/items to temporary storage, verify record capacity, then
commit only that element and its initialization flag. Other elements/flags are
not assigned by the statement. Target availability is checked again before
commit. IMPURE function references in its index, format and output expressions
are deliberately rejected, preventing evaluation from invalidating that file
view; ordinary functions retain existing effect checks. Graph guards reject
cycles and missing expression children. This is a bounded safety restriction,
not a claim that every IMPURE-function-containing internal WRITE is invalid
Fortran. Atomicity is a design property awaiting candidate/runtime tests, not
an empirical guarantee inferred from GNU output.

## Verification status

35 small GNU probes have explicit oracle modes. Their outcomes and exact argv
are recorded outside the source tree in `gnu-probes.json`. Successful cases
require exact stdout and empty stderr; invalid/runtime-boundary cases are not
executed by GNU. Whole-array/section/substring and IMPURE-function cases are
GNU-accepted subset boundaries. Vector-subscripted internal units are rejected
by GNU. First oracle observations are retained independently.

The `original_integer_labels` harness contains exact raw CRLF bodies of
`set_optional_character` and `integer_labels`, with original line ranges and
individual SHA-256 values in the manifest. Only a new module/interface/main
harness surrounds them. The original utility and its separately authorized
one-byte nmax working copy are not changed.

`test/test_internal_write_element.f90` is an unbuilt native test with 119
expected assertions: ordinary acceptance, malformed instruction/designator
metadata, target identity/rank/length, missing subscripts, nonwritable targets,
cycles and out-of-range children. Adapter and runtime rejection are independent.
No FPM test command should be run in this workspace. Central integration must
compile the one test with the exact current app/main compile_commands flags and
link it to the matching shared library from that same current archive.

The focused source cases are not yet candidate-certified. Before release, run
an authorized immutable candidate, review and pin exact diagnostic path,
line/column/message/status/phase for each negative, add adversarial runner tests,
run the native target and existing internal-output/array/purity regressions,
and independently probe the whole working utility's next gate. Do not infer
successful full-program execution from passing source checks or this draft.
