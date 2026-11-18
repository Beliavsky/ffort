# External list READ and bounded BACKSPACE tests

This independent package verifies the focused 0.47 external-input extension.
These scripts never invoke FPM and never copy or build a source tree. Initial GNU
evidence preceded all candidate execution; first-run failures remain retained.

## Verified focused checkpoint

Immutable candidate-second SHA-256
`b2a32e789040973d3317ea07b9d75249a8ae3dca22586ddf0e805df07da62c6d`
passes all 86 source cases, 33 adversarial harness tests and 89-file generator
replay. All fixture source hashes match the initial run. The first candidate
exposed a direct-procedure BACKSPACE producer-dispatch defect; the second fixes
that defect. One pre-run diagnostic expectation was independently corrected to
the already-unsupported COMPLEX declaration. Prior ledger, generator and failing
evidence are preserved with a migration receipt.

The same candidate passes unchanged internal_read (81 cases) and the unchanged
external_read sources with the six reviewed metadata migrations (50 cases).
These are actual second-candidate executions, not merely reassessed old results.
See LEGACY-MIGRATION-PROPOSAL.md and candidate-second-results.json.

## GNU and source provenance

GNU Fortran 14.2.0, with `-std=f2018 -pedantic-errors -fcheck=all -O0`, passes
86 source fixtures: 69 actual successful executions and 17 compile-only
references. The latter include deliberately narrower interpreter policies and
undefined-value safety checks, not equivalent GNU runtime behavior. In particular,
GNU accepts nonfinite real overflow while FortFront's existing finite-value
policy reports an input error. Every successful GNU compile/run has truly empty
stderr, and successful compilation has truly empty stdout.

Ten fixtures preserve the exact CRLF bytes of xutilities lines 790–813, including
the complete `read_alloc_char` implementation. They also preserve the actual
required procedure bodies `present_and_true` (1400–1408), `default_logical`
(3687–3697), and `default_character` (3723–3733). The module, narrowed generic
interface and test drivers are synthetic. No dependency body is simplified.
The source SHA-256 and each range's SHA-256 are pinned in provenance.json.

Coverage includes INTEGER(4/8), REAL(4/8), scalar and rank 1–3 targets, allocated
arrays, fixed and deferred CHARACTER lengths, whole-array storage order, leading
and repeated nulls, slash termination, repeats spanning items, type/kind repeat
mismatches, record-spanning input, quoted continuation with LF/CRLF and empty
records, padding/truncation, zero-sized and zero-length targets, empty input lists,
IOSTAT errors/EOF/past-endfile, undefined-all-on-error behavior, distinct input
units, shared procedure-call cursors, BACKSPACE syntax and record positioning.

The standalone GNU cursor probes and complete observed streams are in
`probe_gnu.py` and `gnu-semantics.json`. The source fixtures make their own
`fort.27`/`fort.28` files in isolated temporary directories. Candidate executions
receive only explicit `--input` bindings to separately generated files. Inputs
are checked for mutation and implicit `fort.N` creation is rejected. No task
reads stdin, user documents, credentials or arbitrary source-requested paths.

## Commands after placing this package at tests/external_list_read

Run `python3 tests/external_list_read/run_tests.py --gfortran /absolute/path/to/gfortran`.
Run `python3 tests/external_list_read/self_test.py` for adversarial harness tests.
Run `python3 tests/external_list_read/check_generator.py` for byte-exact replay.
Add `--candidate /absolute/path/to/fortfront-interpreter` to run the candidate.

When running in the standalone work directory, pass `--original-source` to the
runner, generator and replay checker. For self_test.py set
`EXTERNAL_LIST_ORIGINAL_SOURCE` to the original xutilities.f90 path.

The harness supports `--only REGEX` and `--result NAME`. Candidate diagnostics
must be independently specified as exact source path, line, column and message in
the diagnostic ledger. All 16 negative contracts are pinned from the parser/runtime source design before
any candidate run. The loader also supports explicitly pending development
contracts, and candidate execution of a selection containing one fails closed
before running; GNU-only preparation remains allowed. Never populate expectations automatically from a
candidate's observed diagnostics. Update the generator, then regenerate and rerun
replay if a diagnostic contract changes.

## Comparator and harness guarantees

Numeric token comparisons use exact finite Decimal values, preserving the sign of
zero. Adjacent 64-bit integers remain distinct, tiny nonzero values cannot equal
zero, and no tolerance, NaN, Infinity or float conversion is accepted. CHARACTER
outputs use exact decoded-byte equality with surrogateescape, preserving trailing
spaces, CR/LF distinctions and invalid bytes. Expected empty output means zero
bytes, including in numeric mode. Candidate `--check` stdout and both successful
stages' stderr must be zero bytes. Failures require exact pinned diagnostics and
exact stage statuses; extra lines, host warnings, signals, crashes, backtraces,
timeouts and partial output fail. The 33 self-tests exercise these adversarial
cases and provenance/ledger corruption. Generator replay checks 89 files.

## GNU-backed record contract

- Completed READ consumes the whole final record and discards its unused tail.
- Ordinary record boundaries act as whitespace; `1\n,2,3\n` yields 1,2,3, but
  `1,\n,2,3\n` yields 1,null,2,3. Blank records do not themselves supply nulls.
- Delimited CHARACTER values continue across records without an inserted
  newline. Existing spaces at both record edges remain part of the value.
  A closed quote at record end remains closed; a next-record opening quote
  introduces another value. Nondelimited CHARACTER values stop at record end.
- Empty input lists and zero-sized target lists advance one record. They report
  EOF on an empty input, followed by a positive past-endfile result.
- BACKSPACE after an ordinary READ repositions before its last consumed record,
  even if that READ spanned multiple records. It also handles empty and final
  unterminated records. At an already connected initial point it is a no-op.
- One BACKSPACE after EOF clears the endfile state without moving to the last
  data record. Another READ reaches EOF again. Two BACKSPACEs from after EOF
  allow the last data record to be reread. An empty bound file stays empty.
- The GNU oracle initially has an unconnected unit, whereas a candidate binding
  is already connected. Therefore initial-point behavior is tested after an
  initial READ and two BACKSPACEs, not by equating unconnected GNU behavior with
  an explicitly bound candidate. The standalone unconnected GNU probe reports a
  positive status and is not a candidate expected-success fixture.

The above details are backed by the included executable GNU evidence. Primary
vendor references provide additional context: Intel's [list-directed READ rules](https://www.intel.com/content/www/us/en/docs/fortran-compiler/developer-guide-reference/2023-2/rules-for-list-directed-sequential-read-statements.html)
and [BACKSPACE reference](https://www.intel.com/content/www/us/en/docs/fortran-compiler/developer-guide-reference/2023-2/backspace.html).

## Integration status

Two additional native test sources are supplied for the integrating build:
`test_external_list_read_metadata.f90` (130 lines) mutates public READ and
BACKSPACE IR, checks neutral fields, independent source binding and PURE/SIMPLE/
ordinary-function effects; `test_external_list_read_runtime.f90` (146 lines) uses
only caller-owned `input_unit_t` arrays to check list/cursor/BACKSPACE behavior,
corrupt descriptors and metadata, zero-sized bound files, budget and record
limits, distinct caller state, absent OPTIONALs and aliased arguments.

The coordinator owns native test compilation/execution and records those results
separately. The full existing regression matrix and final package identity are
not established by this focused package. No release readiness or full xutilities
acceptance follows from these focused checks. Preserve the existing bounded unit/record/storage/work
limits and safety-diagnostic behavior; adding list input or BACKSPACE grants no
file-opening authority.

## Final owned native and whole-source checkpoint

Both new native programs were compiled directly with every compiler flag from
the same ordinary-debug FPM app command ledger, substituting only source/object
paths. The metadata program passes 101 assertions and runtime program 95.
The library and executable identities, commands and streams are retained in
`evidence/exact-profile-native-results.json`; this is focused verification, not
a full native aggregate. Earlier preliminary links and failures remain preserved
in the development evidence.

The portable full-working-source boundary harness preserves the original and
its sole authorized nmax digit change. On the historical 0.47 candidate both check and run
reject cleanly at1047:11 in repeat_char, whose untyped CHARACTER constructor
has runtime-dependent length. GNU independently compiles/runs the full adapted
program. No FortFront whole-program execution or random-sequence equality is
claimed. Evidence is retained here and the maintained harness remains under
`tests/utilities_working`.

Historical native expectation changes are restricted to absent external READ
format metadata, which now represents valid list input: the public predicate
accepts it, the source adapter still rejects its substitution into an `(A)`
source, and direct execution explicitly checks cursor advancement. The malformed
format case now uses an allocated invalid `*` rather than missing metadata.
No original or historical source fixture body is changed.

The descriptor-length constructor extension advances the maintained working
source boundary to1192:18, SYSTEM_CLOCK in init_wall_time. The above1047 record
remains historical evidence, not the current expectation; see
`tests/dynamic_character_constructor` and `tests/utilities_working`.
