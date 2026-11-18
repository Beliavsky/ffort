# Bounded bare CHARACTER vector actuals

## Result and scope

An unparenthesized rank-one default-kind CHARACTER vector section can now be
passed to a non-TARGET, non-POINTER, non-ALLOCATABLE, non-CLASS assumed-shape
`INTENT(IN)` dummy. Both function and subroutine calls are covered. Existing
parenthesized gathered expressions remain independent value snapshots.

This closes the original utilities line 2523,
`call set_alloc(xx(iuse),xuse)`, without rewriting that call. A smaller executable
closure retains the exact original CRLF procedure bodies of `match_char`
(lines 2496–2515), `select_match_vec_char` (2517–2524), and
`set_alloc_character_vec` (2626–2634). Only its module/interface/main harness is
new. Its actual output matches GNU: `red`, `red`, `0`, `blu`, `grn`, each followed
by a newline. `tests/character_gather_actual/check_original.py` verifies all 50
fixture identities and the three raw source ranges against the untouched input.

The full utilities program is **not supported or successfully executed**.
The historical fourth 0.52 preview rejects the authorized one-byte working source at
2678:36, `Vector subscripts support only rank-one INTEGER row indices of a matrix`.
That is a source-stage rejection on both check and run, not an executed runtime
failure. The untouched original remains at its independent 9329:55 array-size
boundary. Numeric rank-one vector gather is outside this change.

## Standard semantics versus implementation boundaries

[J3/24-007, section 15.5.2.5 paragraph 21](https://j3-fortran.org/doc/year/24/24-007.pdf)
permits the read-only association used here. A vector-subscripted actual
associated with an ordinary nonelemental, non-VALUE dummy makes that dummy
nondefinable; OUT/INOUT and ASYNCHRONOUS/VOLATILE associations are excluded.
The utility's first dummy is assumed-shape `CHARACTER(*)`, `INTENT(IN)`.
Extra parentheses are not required by the language.

The supported subset is intentionally smaller. Explicit-shape, unspecified
INTENT, TARGET, POINTER, ALLOCATABLE and CLASS dummy cases are not added. An
excluded case is not necessarily invalid Fortran. The existing gather engine's
limits remain, including the separately documented CHARACTER selector-component
composition boundary. This change is argument association, not a general
expansion of vector-index expression grammar or alias analysis.

A bare section retains its backing-array identity even though its selected
values are staged. Before callee entry or OUT-descriptor invalidation, the
runtime rejects a writable actual sharing that backing array. This is a
conservative **whole-base reservation**: even disjoint writable selections and
an empty bare gather with writable same-base output are rejected. Two read-only
inputs are allowed. A PARAMETER base requires no mutable backing reservation.
The preexisting host/USE conflict policy also includes the bare gather; even a
read-only shared-host access can be rejected by that conservative policy.
These safety/subset cases are compiled but not executed by the GNU oracle.

A parenthesized same-base expression is different: it is an independent snapshot
and can be followed by resizing a separate OUT dummy backed by the original
array. Neither the source nor its recorded parenthesization is silently changed.

## Independent guards and source identity

`bare_character_gather_input` in `fi_ir` is independently consulted by parser,
adapter and runtime. Existing gather validation, length handling and element
staging remain in force. The runtime does not reevaluate the vector merely to
construct alias offsets, and the read-only binding never copies out.

The adapter independently verifies the gathered actual's parenthesized marker
against retained producer tokens. It uses written argument order, with the
existing formal/keyword mapping, and handles continuation trivia, nested calls,
modern and legacy constructors, strings, and a type-bound receiver. CALL nodes
anchor at their statement/callee occurrence. Producer function nodes anchor at
the closing parenthesis, so their actual-list opener is recovered by balancing
operator tokens backwards. Neither comments nor strings affect that balance.

Native malformed-IR tests require marker mutations in both directions to be
rejected. Runtime alias protection is tested independently of adapter rejection.

## Verification and preserved failures

The tested fourth immutable CLI is
`21a75fabbf300f7fa3907fceeb6ab6be4646e207682bc7854195c18ed5d8ccc4`.
Its matching shared-build archive is
`28987ce2cd414d6e5ce96bb12b46d1db41ec31941a008aea0ec6d0f3c80507be`.
These are focused preview results, not a claim of completed clean release
certification.

- 50 source contracts pass: 32 successful executions and 18 pinned rejections.
  Runtime-boundary cases must first check silently. Every negative fixes the
  complete source path, line, column, message, newline, status and stage.
  Successful check is silent; successful run has exact stdout and empty stderr.
- GNU strict F2018: 32 executions, 14 compile-only cases, four expected compile
  rejections. The original FORALL closure has one exact pinned obsolescence
  warning. Other successful compile/run diagnostics are empty. Invalid alias,
  undefined, unallocated and bounds-error cases are never run by GNU.
- Unchanged native tests pass 71 and 60 assertions. Central integration compiled
  each source using the exact active app profile and matching archive, with all
  compile/link/run commands and streams retained.
- 74 strict-runner adversarial tests pass under normal Python and `python -O`.
  The original 29 are retained; 45 additional tests exercise malformed stage
  records across candidate check/run, GNU compile/run and version stages.
  The 50-source/raw-CRLF audit also passes in both modes.

Evidence in `tests/character_gather_actual/oracle-evidence` is chronological:

1. The first 35 fixtures and initial outcomes remain intact. One initial output
   expectation was corrected from no output to one empty formatted record;
   `first-manifest.json` and `fixture-preservation.json` disclose that correction.
   No original source bytes changed. Three alias fixtures were added, then ten
   marker controls and two additional source-anchor controls, for 50 total.
2. The second preview passed 38 source cases but the original 71-assertion native
   test exposed acceptance of a stripped source-parentheses marker. The initial
   failed native test and separate observational probe remain preserved.
3. The first marker correction passed native 71 but failed native 60 on a valid
   function actual. Its 50-case source run had exactly three failures:
   `function_input`, `marker_6`, `marker_7`. The producer's function location had
   been incorrectly assumed to be its starting token. The earlier source review
   is retained alongside the corrected review; it is not passing execution
   evidence. A separate incremental compile-database setup failure invoked no
   native compiler and is identified separately from the real candidate failure.
4. The narrow closing-token correction resolves all three unchanged source cases
   and the unchanged native 60. Fourth-preview strict/native receipts establish
   the passing results above. Earlier failures were not overwritten.

A later harness-only followup tightens the recorded-stage schema without
changing any source fixture, expected program semantics or core file. Status
must be a nonnegative integer, never a JSON boolean; stdout and stderr must be
present strings; an optional timeout flag must be exactly boolean false. Crash
markers and corrupted decoded text are rejected before semantic comparison,
including GNU execution and all candidate/GNU version records. A further pure
schema successor requires any present `valid_utf8` field to be exactly boolean
true and requires non-whitespace GNU stderr for an expected source rejection.
The previous schema followup and its reproduced gaps remain preserved. The immutable
fourth-preview 50 records and three version records revalidate under this
stronger guard. Initial schema-gap observations and the focused package remain
preserved separately; this is evidence validation, not another compiler build.

## Reproduction and integration

Run from the release root with an independently pinned candidate hash:

```sh
python3 tests/character_gather_actual/check_original.py
python3 tests/character_gather_actual/test_contract.py
python3 tests/character_gather_actual/run_tests.py \
  --candidate /absolute/path/to/fortfront-interpreter \
  --expected-sha FULL_CANDIDATE_SHA256 \
  --gfortran /absolute/path/to/gfortran \
  --result tests/character_gather_actual/results.json
```

The runner records exact commands, compiler identity, candidate before/after
identity and banner, source identities, streams, phase and oracle mode. It uses
`-std=f2018 -pedantic-errors -O0 -fcheck=all -ffpe-trap=invalid,zero,overflow
-ffree-line-length-none`, without a GNU dialect fallback or diagnostic suppression.
For native direct-link instructions and exact test hashes, see
`tests/character_gather_actual/native-handoff.json`. Do not use
`fpm test --target` in the constrained integration workspace: that FPM still
builds/links the full automatic-test set before filtering execution.

The final core changes only four interpreter files relative to the first 0.52
snapshot; no vendor delta is needed. Historical application order is core
`014d6949`, marker `804c2b80`, then function-anchor `d3b87ac7`.
`final-consolidated-core.patch` is an equivalent single patch against that first
snapshot, not an additional patch to apply after those three.

## numeric extension and current utility boundary

Historical 0.53 checkpoint: The 0.53 numeric rank-one extension advances the byte-preserved adapted working source to 2992:1, `INQUIRE`. This is still a source-stage rejection, not interpreted whole-program execution. The untouched original retains its 9329:55 resource-cap rejection. INQUIRE is excluded from this checkpoint; no file-access or ordinary-function effect policy is relaxed. Numeric rank-one bare actuals have a [separate contract](NUMERIC-VECTOR-GATHER.md); they do not widen the CHARACTER descriptor, alias or effect rules.

## Current bounded input-name inquiry

The focused 0.54 composition adds only [registered input NAME inquiry](INQUIRE_NAME.md). The byte-preserved adapted working source now stops at 2995:41 on external READ to a CHARACTER array element; the untouched original still stops at 9329:55 under the unchanged array cap. Both remain pre-execution source rejections. See the [working-source evidence](../tests/utilities_working/README.md). READ-element support remains outside this checkpoint, and no host-unit discovery, general file access, writable-actual or ordinary-function effect relaxation is implied.
