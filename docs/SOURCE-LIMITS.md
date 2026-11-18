# Configuring source capacity

The default source-size cap is **1,048,576 bytes (1 MiB)**, increased from
65,536 bytes. The independent lexical cap is **262,144 tokens**, increased from
20,000. Both limits are explicit, build-time constants in `src/fi_limits.f90`:

```fortran
integer, parameter :: max_source_bytes=1048576
integer, parameter :: max_tokens=262144
```

The CLI uses `max_source_bytes` before allocating or reading the source buffer.
The reusable `parse_subset` and `compile_program` entry points enforce the same
cap before allocating lexical storage. Oversize input is rejected with status 1
and a diagnostic that prints the configured cap. File size counts bytes exactly,
including both bytes of a CRLF newline. Because accepted source is ASCII, the
reusable API's character length has the same byte interpretation.

`max_tokens` includes newline and semicolon separators, plus one final synthetic
separator and the EOF token. Exactly that many tokens are admitted; the next
token fails explicitly. Token storage starts at at most 256 entries and doubles
as needed, capped at `max_tokens`. Moving existing token text avoids copying
each allocated string during growth. Allocation failures for the source buffer
and growing token array produce diagnostics instead of unchecked allocation
termination. This does not claim that every allocation in the interpreter or
vendored frontend has an allocation-failure recovery path.

Use positive default-INTEGER constants, with `max_source_bytes <= huge(0)-2`
and `max_tokens >= 8`. Keep both far below the representable maximum; available
memory and frontend work, not integer representation, determine practical caps.
The shipped boundary suites target a source cap above 65,537 and a token cap
above 20,001 but smaller than the byte cap. Those relations let them test the
two boundaries independently; smaller custom caps need adjusted test fixtures.

Rebuild all dependent modules after changing either constant:

```sh
fpm clean --all
fpm build
python scripts/verify.py
```

These constants do not raise symbol, procedure, expression, instruction, nesting,
132-column, array, CHARACTER, PRINT or runtime-work limits. A larger source can
still be unsupported or exceed one of those independent limits. Source capacity
does not add language features or separate compilation. The prototype still
requires same-file modules followed by one main program.

## Boundary coverage

`test/test_source_limits.f90` verifies the byte and token caps below, exactly at
and above each boundary through the reusable parser, the exact byte boundary
through the full frontend, rejection through the compile API, and successful
compilation after a limit error in the same process.

`tests/source_limits/run_tests.py` tests both CLI check mode and execution for
old-cap regressions, exact byte/token boundaries, CRLF accounting, above-cap
rejections, and unchanged long-line/ASCII rejection. Three larger valid programs
are independently compiled and run with GNU Fortran. The test reads the actual
configured constants instead of repeating the default numbers as expectations.
The general CLI and array-limit suites also derive the byte cap from this file.

## Supplied large library

The unchanged `xutilities.f90` input is 338,883 bytes and 9,806 lines, with SHA-256
`c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`.
The 0.18.0 baseline rejects it at the old 65,536-byte gate. With this change it
passes that gate, and the next diagnostic is at line 25, column 38:

```text
Unsupported dotted operator: .in.
```

Both check mode and execution return status 1 without program output. This
is a language-subset rejection, not evidence that the complete library can run.
The input also includes features outside the current contract, and several
lines longer than 132 columns. Increasing source capacity must not silently
strip, rewrite or skip those constructs. The original input was not modified.
