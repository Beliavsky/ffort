# Proposed 0.47 tests-only migrations

## Evidence retained before any migration

Frozen first candidate SHA-256:
793a9893f05b40e198b31757a5ac2014f16c1c210f274f65c0cfd634d9dbd216.

- New external-list suite: 84/86 pass. GNU references all 86 pass. Initial result
  is retained in candidate-first-results.json.
- Existing external_read: 44/50 pass under unchanged 0.46 metadata. GNU passes
  all 50 references (27 executions and 23 compile-only).
- Existing internal_read: all 81 pass under unchanged 0.46 metadata. GNU passes
  37 executions, 37 compile-only references and 7 compile-rejection references.
- Source and metadata snapshots are hashed in legacy-audit-input-hashes.json.
- No baseline source, expected outcome, manifest or provenance file was changed.

## External-read manifest and diagnostic ledger

The unchanged `external_list.f90` uses a declared unit variable and
`read(u,*)line`, but supplies no binding. It now correctly passes CHECK and exits
2 at run time with `external input unit is not explicitly bound` at 6:1.
Proposed migration: category invalid -> runtime, retain GNU compile-only,
retain empty stdout and empty bindings. Pin the runtime diagnostic at 6:1.
This records a syntax promotion without silently granting file access.

Five cases still reject in both phases with the same line and column:
external_width, external_array, external_literal_unit,
external_unit_iostat_alias, external_read_substring. Only the generic parser
message changes to the explicit new source contract:

    External READ requires an INTEGER unit variable, list-directed whole local numeric or CHARACTER targets or literal (A) scalar CHARACTER, and optional INTEGER IOSTAT outside PURE/SIMPLE procedures

Reviewed metadata files are in legacy-proposed/. Initial retained streams
reassess at 50/50 under those contracts. A subsequent actual execution of all
50 cases and GNU references against candidate-second also passes, recorded in
legacy-external-second-migrated-results.json. The unchanged internal suite
likewise passes all 81 against candidate-second.

The existing source hashes and provenance remain unchanged. The suite still has
50 cases and 22 negative cases, so the self-test's coverage counts need no update.
The two existing internal_read boundary fixtures external_unit and external_stdin
use literal 5 and *, respectively. Neither is promoted by the declared-unit-only
contract. All internal_read metadata should remain unchanged for this milestone.

## Legacy native test assumptions

The old native external READ metadata test treats deallocating an `(A)` format
as corruption in mutation case 19. That descriptor now represents valid
list-directed input. Test its public gate as accepted, then still require the
independent producer to reject that descriptor against the original `(A)` source.
Change `reject_statement('read(unit,*) line')` into the corresponding accepted
source/producer check. Do not change `(A)` array, width or literal-unit negatives.

The old native external READ runtime test likewise treats deallocating format as
corruption in mutation case 12. That is now valid public-IR list input. Move it
out of the corruption loop and test successful execution/cursor advancement with
the existing input bytes, or replace the corruption with an allocated invalid
format and add the accepted-list check explicitly. Do not merely relax runtime
error checking for the whole mutation loop.

## Generator and provenance audit

No generate script is packaged in the frozen external_read or internal_read
suite directory. Their manifests are the current packaged classification source.
The external suite preserves read_words_line, the internal suite preserves
read_int_vec_alloc/read_real_vec_alloc, and neither provenance range changes.
The new suite's replayable generator and provenance are separate and do not
rewrite those historical fixtures.

A historical standalone script internal-read-work/generate_tests.py targets an
old 0.42 workspace, not this release. It still classifies character_target as
unsupported, which was already superseded in 0.46. Do not run it as a current
release generator without deliberately porting all later manifest changes.
No 0.47 external-unit or stdin promotion is needed there.

## New-suite findings, not hidden by this proposal

- nested_call_cursor correctly expects success. First candidate rejects
  BACKSPACE(u) at line 12:0 inside replay_one with
  `FortFront adapter: missing statement`. Keep the fixture and expectation;
  implementation/adapter correction is required.
- read_complex_unsupported correctly expects compilation rejection, but its
  pre-run diagnostic pin incorrectly assumes the declaration reaches READ.
  Parser source's type_name does not implement COMPLEX, so the correct existing
  boundary is the declaration at 4:1:
  `Undeclared variable or unsupported statement: complex`.
  Proposed correction: preserve source/category and pin this independently
  source-supported earlier boundary. This is not an external-I/O regression.
  The initial mismatching result remains retained either way.

## Final checkpoint

Candidate-second b2a32e789040973d3317ea07b9d75249a8ae3dca22586ddf0e805df07da62c6d
passes all 86 new fixtures. The producer dispatcher defect is corrected; every
fixture remains byte-identical to the first run. Only the independently justified
COMPLEX diagnostic pin changed, with initial ledger and generator retained under
initial-evidence/ and an explicit migration receipt. The coordinator owns the
legacy native migration patch, native execution and verifier integration.
