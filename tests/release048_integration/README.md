# Independent 0.48 cross-feature composition

This additive suite contains 29 synthetic cross-feature sources. No utility or
M_intrinsics original is rewritten or duplicated as an authoritative provenance
fixture. The bit owner retains the exact IOR/NOT/BTEST originals. The original 0.48
BTEST slash boundary is preserved as historical evidence; 0.49 now executes it.

Coverage combines descriptor-length CHARACTER constructors and snapshot assignment
with INTEGER4/8 IAND/IOR/IEOR/NOT/BTEST, scalar BIT_SIZE inside surrounding arrays,
B/O/Z formatting, internal padding, runtime FORMAT, constructor/output implied-DO,
ordinary group reversion, T/TL/TR backward overwrite, nonadvancing records and
failing-statement output atomicity. Values beyond binary64 remain exact integers.
The existing 65536-character record cap is exercised, not raised.

The three timing compositions use actual host calls. They print only deterministic
assertion results, never sample values. SYSTEM_CLOCK asserts its available range or
unavailable sentinel contract; CPU_TIME asserts finite results and nondecrease only
when both samples are available. No fake clock, callback, sleep or timing equality
is used. Forwarding absent COUNT is separate from comparing clock samples.

## Verified stage

All 29 composition outcomes pass immutable merged preview
`b1417abd617fb05c599c417bd68946541beddb43ddc3bbec2e8b7d1b7086c3e7`
(version 0.48.0), with the same executable hash before/after. GNU supplies 18
strict exact-output executions, 10 compile-only references and one pinned GNU
compilation rejection. These stages are not interchangeable execution claims.
All 43 adversarial/reproduction harness tests pass. No interpreter/library build,
shared-tree edit or core change was performed for this suite. Full certification
and the original-example survey remain separate integration steps.

```
python3 tests/release048_integration/test_runner.py
python3 tests/release048_integration/run_tests.py --gfortran /path/to/gfortran
python3 tests/release048_integration/run_tests.py --gfortran /path/to/gfortran --candidate /path/to/frozen/app
```

## Honest boundaries and oracle distinctions

* Two preserved initial FMT probes first hit the existing reserved identifier
  OUT boundary at 4:16. Separate buffer-named sources reach the intended internal
  array-element FMT rejection (7:11) and positive whole-scalar staging path.
  No original probe was rewritten or silently substituted.
* REAL B/O/Z editing remains a bounded exclusion, not an invalid Fortran claim.
  The unchanged `slash_retained_boundary` is promoted in 0.49 to full candidate/GNU
  execution with exact `SAFE\n 3\n\n` records; its original name and bytes remain.
* Invalid evaluated BTEST positions, unequal dynamic CHARACTER constructor
  lengths and output exceeding the unchanged record cap are safety profiles.
  GNU compiles but never executes these invalid/unsafe sources.
* `kind_bit_metadata_no_read` is preserved with a constant invalid POS under KIND.
  GNU rejects that constant constraint; the interpreter metadata contract is
  tested independently. It is not a successful GNU comparison. A separate source
  uses undefined variable POS to test metadata non-evaluation with GNU agreement.
* `machine_minimum_z_zero_minimum` uses the processor-specific INTEGER8 machine
  minimum outside the symmetric Fortran arithmetic model. The independent fixed
  64-bit residue oracle expects 8000000000000000. GNU14's Z m=0 blanking is retained
  separately; this is not counted as execution agreement or a general standard
  conformance allegation. See the owned B/O/Z suite for the full raw observations.
* GNU14.2 SIGSEGVs at both -O0 and -O2 when forwarding an absent OPTIONAL COUNT
  with present RATE/MAX. The exact source and raw crash observations are retained
  in `oracle-evidence/gnu-absent-count-profiles.json`. The candidate contract uses
  the absent optional argument rule (F2018 15.5.2.12p4), as confirmed by the timing
  owner. This profile is GNU compile-only, never a crash-as-pass execution claim.
  Primary text: https://j3-fortran.org/doc/year/18/18-007r1.pdf

## Strict runner and attempted-source preservation

Every output record, space, hex letter and newline is exact. No case may opt into
numeric normalization. The inherited exact-Decimal comparator is adversarially
tested but unused by this suite. Success check/stdout/stderr silence and negative
status/path/line/column/diagnostic are mandatory. Crash, trace, ICE and timeout
markers fail candidate checks; known GNU defects are separately stored observations.

The 22 initial attempted sources and their manifest/identity/first outcomes remain
byte-preserved under `oracle-evidence`. Two synthetic declaration mistakes were
corrected after retaining those attempts: missing implied-DO index declaration and
variable P conflicting with PROGRAM P. A third retained timing attempt used M as
a main variable while USE-associated module M occupied that name; the final source
uses MX. These are fixture repairs, not feature gains or changes to original code.
The source identity manifest and generator replay pin the maintained source set.
Empty input directories are unnecessary in file-only archives.

## Initial merged outcomes retained

The initial 27-case run reported three mismatches: two earlier OUT-name boundaries
and a provisional BTEST diagnostic column (correctly 18). No implementation defect
was found. Only their manifest/generator expectation metadata changed. Two new
buffer-named probes were then added. The second run pinned the distinct internal
WRITE diagnostic text; final run passes all 29. Raw first/second/final receipts and
all prepreview source hashes are retained. All 27 prepreview sources remain
byte-identical; the original 22 GNU preparation attempts are also preserved.

The 0.49 slash-only metadata migration changes one outcome from compile-only
GNU/runtime rejection to exact execution. The earlier 0.48 verified counts above
remain historical, not counts for the updated profile. Generator replay preserves
all 29 maintained Fortran sources and the complete SOURCE-IDENTITY.json.
