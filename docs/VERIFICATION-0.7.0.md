# Verification of prototype 0.7.0

Recorded 14 November 2026 on Linux x86-64 with GNU Fortran 14.2.0,
fpm 0.13.0 alpha and Python 3.12.14. GNU reference commands use
`-std=f2018 -pedantic-errors -fcheck=all` (the source corpus also uses `-O0`).

## Clean extraction and full verification

The complete release candidate was archived, extracted into a fresh directory
whose path contains spaces, and rebuilt without a build cache or network
dependency downloads using `python3 scripts/verify.py`. All aggregate checks pass.
All 1443 implementation, test, fixture, manifest, example, verifier
and vendored source inputs were compared byte-for-byte with the checked extraction
before final packaging. Only evidence/documentation was updated afterward.

- Independent: **226/226 interpreter cases**, 206 GNU checks, 20 explicit skips.
- Arrays: **179/179 interpreter cases**, 152 GNU checks, 27 explicit skips.
- Program forms: **87/87 interpreter cases**, 84 GNU checks, 3 explicit skips.
- Whole arrays: **147/147 interpreter cases**, 121 GNU checks, 26 explicit skips.
- Sections: **183/183 interpreter cases**, 168 GNU checks, 15 explicit skips.
- Module functions: **89/89 interpreter cases**, 76 GNU checks, 13 explicit skips.
- Numerical procedures: **88/88 interpreter cases**, 84 GNU checks, 4 explicit skips.

Combined: **999/999 interpreter corpus cases**, **891 applicable GNU
checks**, **108 explicit skips**, **zero failures**. Skips are not compiler passes.
In addition, one deterministic arithmetic matrix program produces **272 formatted
REAL32/REAL64/mixed-kind values that exactly match GNU Fortran byte for byte**.
All **14 native Fortran test programs**, **17 CLI/resource checks** and
**87 runner self-tests** also pass. Native tests include deliberate inconsistent
IR, call-frame, real-kind, visibility, format, producer and control-flow probes.

The clean debug executable SHA-256 is
`d19f73d64ab3820322427e2cb705407107af337a4f522b6335d8c53f888db1e8`. This identifies the checked build, not a distributed binary;
paths/debug metadata can change the hash on another machine. Final ZIP extraction
and every entry in MANIFEST.sha256 were checked after packaging.

## Exact user programs

The exact Black-Scholes and module-subroutine sources are retained unchanged in
`examples/black_scholes.f90` and `examples/module_subroutine.f90`, and again in the
independent corpus. Black-Scholes prints a call price of **10.4505835722** and put
price of **5.5735260223** for the at-the-money example. Its original benchmark and
put-call parity assertions pass, including zero volatility and expiration cases.
The entire formatted Black-Scholes output is byte-identical to the checked GNU
Fortran output. The subroutine prints the values **2.29999995** and **4.59999990**
with its original labels. List-directed spacing is intentionally implementation
specific. Earlier requested examples still print 32, 55 and approximately 4.6.

## Scope and limits

General added features are documented in README.md and NUMERICAL-PROCEDURES.md:
REAL64 and kind-qualified literals, immutable module/host constants, ISO_FORTRAN_ENV
REAL32/REAL64, PUBLIC/PRIVATE and USE ONLY, typed/PURE function headers,
module/internal subroutines and scalar INTENT(IN) arguments, character dummy
arguments, CALL/RETURN, single-line IF/ERROR STOP, between-token continuation,
EXP/LOG/SQRT/ERFC and restricted literal formatted PRINT. The private recognizer,
required FortFront AST/binding/type cross-check, and bounded interpreter remain
separate. No compiler is invoked to execute interpreted programs.

OUT/INOUT, optional/keyword/array arguments, mutable host/module storage,
recursion, file I/O, full FORMAT syntax and other unlisted Fortran features remain
outside the subset. Precision checks are tight targeted tests, not a statement
of whole-language or cross-platform conformance. Windows has not been executed.

## Preservation and provenance

All **911 prior source fixtures** are byte-identical to 0.6.0. Four
previously unsupported but valid programs now have success expectations: typed
function headers, USE ONLY, RETURN and single-line IF. One CLI expectation now
matches the clearer empty-source diagnostic. Other prior contracts remain checked.
**455 of 460 existing vendored files** are byte-identical;
changed files and checksums are listed in `verification/0.7.0/source-preservation.json`.
Patches 0004, 0005 and 0006 document scope-aware named-kind/intrinsic corrections,
complete IF parsing inside procedures, and exponent-only literal/ERFC handling; prior patches and original licenses remain.
The root and FortFront MIT licenses are unchanged, and FortFront attribution is
retained. No upstream authorship, endorsement or whole-upstream-suite pass is claimed.

The ZIP is a complete source release with pinned dependencies, licenses, tests,
examples and evidence. It excludes compilers, binaries, build caches and Python
bytecode. MANIFEST.sha256 covers every included file except itself. Historical
reports remain provenance; current evidence is the seven tests/*/results.json
files, arithmetic-matrix report and verification/0.7.0 clean-room log.
