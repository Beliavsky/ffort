# Bounded INQUIRE NAME

`INQUIRE(UNIT=iu, NAME=file_name)` queries the name supplied for an explicitly
registered read-only input unit. UNIT and NAME are required named controls, in
either order. UNIT must be a whole scalar INTEGER(4/8) variable. NAME must be a
whole writable local default-CHARACTER scalar, including supported writable
CHARACTER dummies. An allocatable scalar must already be allocated; inquiry
does not allocate or resize it. The name is truncated or blank-padded to its
current length.

## Explicit input boundary

The CLI records the exact PATH spelling from `--input UNIT=PATH`; an embedding
caller can supply `input_unit_t%name`. A present name must contain 1..4096
characters without NUL. The query does not open files, search paths, discover
host units, or fall back to stdin. The registered name is metadata, not a new
filesystem lookup. Unbound or unnamed units reject before NAME is defined.
Old unnamed registrations remain valid for READ/BACKSPACE. Input data, cursor
and endfile status are unchanged by successful or failed inquiry.

The existing external-input ownership and ordinary-function/PURE/SIMPLE effect
restrictions remain. UNIT is evaluated once; target storage, evaluated unit
kind and registration are validated before staging. Copy/padding work is charged
to the step budget before the single target commit. `--check` does not open the
registered input file, including a nonexistent path.

This is not all standard INQUIRE syntax. FILE, EXIST, OPENED, IOSTAT, positional
UNIT, literal/arithmetic UNIT, NAME substrings and NAME array elements remain
outside this bounded lane. Such exclusions are not claims that those forms are
illegal Fortran. No full-utilities execution is claimed.

## Verified focused contracts

On immutable fifth preview 0.54.0 (INQUIRE, F0.d and array-element CHARACTER
substring), CLI SHA
`14a7d889568e7bf8233dbaeff67311e14d8502391b72b00ca1332a12078d17d2`:

- 36 source contracts: 14 successful runs, 19 exact checking rejections, 3 exact
 runtime rejections. Successful checks are silent; successful stdout is exact.
- 36 GNU plans: 14 executions, 11 compile-only and 11 required source rejections.
 GNU setup replaces only the explicit marker comment with OPEN of the test
 file; this is a documented setup adaptation, not unchanged-source equality.
- The exact utility line 2992, including CRLF, is retained in a focused module/main
 harness. It is not the complete read_comments routine or main program.
- Two central matching-library native drivers pass 325 and 140 assertions.

On the preceding INQUIRE-only second preview, also preserved separately:

- 226 unchanged nearby source cases pass across external_read 50,
 external_list_read 86, scalar_allocatable_character 67 and pure_internal_write 23.
 Separate central evidence covers eight unchanged nearby native programs.

The first preview failures are preserved: direct procedure INQUIRE was missing
from the producer AST. Vendor patch 0116 adds only the missing dispatch. The
producer-native import correction changes no semantic assertions. Initial
source cases, positive stdout and the metadata native remain byte-identical.

## Running the focused suite

```sh
python tests/inquire_name/run_tests.py --exe /absolute/immutable/fortfront-interpreter --sha256 EXACT_SHA256 --results /new/results.json --gnu /absolute/gfortran --gnu-sha256 INDEPENDENT_EXACT_GNU_SHA256
python tests/inquire_name/test_runner.py --results /new/harness-normal.json
python -O tests/inquire_name/test_runner.py --results /new/harness-optimized.json
```

The runner creates `input sample.dat` containing exactly `alpha\nbeta\n` and
registers relative spelling `17=input sample.dat`. An absolute input path would
change NAME and must not be substituted. Every candidate, GNU and version stage
records exact commands, status and streams. Strict validation rejects booleans
as integer statuses, missing or malformed streams/commands/cwd, timeouts,
invalid encoding and crash markers before semantic checks. Diagnostics match
source path, line, column, message, status and checking/runtime phase. The
41-input source/policy inventory, candidate and GNU executable identities are
bound before and after execution. The GNU identity is supplied independently,
not trusted merely because two receipt fields agree. Output reservation is
exclusive and rejects symlink paths; spawn failures and raw stream bytes are
preserved. All 11 required GNU rejections match exact source-located GNU 14.2
diagnostics, normalizing only the generated oracle source path.

Pure harness tests pass 5222 poisoned controls and 144 valid controls under normal
Python and `-O` (nine methods). Independent bounded review passes for the exact
R5 policy. Earlier schema failures, reviewer findings, policies and raw receipts
are preserved, including working-directory, wrapper-error and self-consistent
but untrusted compiler-hash holes. Harness hardening changes no source bodies,
positive outputs or rejection modes. This is focused evidence, not a full clean
release certification.

Compile natives directly with the complete current app profile flags and link
the library/archive from that exact build. Do not use `fpm test --target` in the
constrained workspace: that FPM version builds all automatic tests first.

## Scope and historical audit

A broad source-bearing inventory of the delivered 0.53 archive found no other
maintained INQUIRE rejection contract outside the full utilities gate. The
utilities gate metadata is intentionally unchanged pending the separate READ
array-element work. The original utilities source and its one-byte-size-adjusted
working copy remain untouched. Current focused evidence does not establish that
the complete utilities program checks or runs.

The maintained GNU contract uses the fixed GNU 14.2 executable identity
`406a8ebf8691187132f55a124d6ca47d99978645f6d03bb1d6926a7e5efcd730`.
Using another compiler requires a separately reviewed oracle contract rather
than treating a different failure message as equivalent. The runner must be
supplied the independently verified compiler SHA, not one read from its own
result. Historical raw receipts retain their original absolute execution/source
paths; no receipt is rewritten to simulate a run after package relocation.

The fifth-preview rerun uses the same 36 source bodies and exact R5 contracts.
Fourth and fifth source/GNU and matching-library native receipts are preserved
in the additive evidence handoff. The earlier focused archive and its third
preview receipt remain immutable. READ array-element support remains excluded;
the separately measured full-working-utilities source gate is still 2995:41.
