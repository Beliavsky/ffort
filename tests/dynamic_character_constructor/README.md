# Descriptor-length CHARACTER constructor verification

Independent 0.48 focused verification: 72 source fixtures pass candidate
`2e65707112d177803824f441e739634facfff1c0210b367912c221650028a350`.
The stages are 60 successful executions, 10 controlled runtime errors and 2 source
rejections. GNU 14.2 independently executes 51 with exact expected output;
20 cases are compile-only references, and one has a pinned GNU compiler
limitation. These distinctions are not interchangeable execution claims.

## Original bodies and contract

Eighteen wrappers retain exact original CRLF bodies from `xutilities.f90`:
`repeat_char` (lines 1041–1048), `repeat_char_vec` (1089–1101) and original
`present_and_false` (1410–1418). `provenance.json` pins the complete original,
body ranges/hashes and every wrapper. The callers are synthetic. These are
complete procedure closures, not full-utility execution.

Untyped CHARACTER constructors use descriptor-known scalar/array operands,
elements/sections, concatenations and nested constructor bodies. Runtime lengths
must agree, including empty branches. Length inquiry does not read undefined
CHARACTER values or zero-trip loop controls. Fixed declared lengths do not require
allocation for metadata-only LEN; dynamic lengths require present/allocated
valid descriptors. Data-dependent TRIM, dynamic substring bounds and dynamic
function-result lengths remain outside this subset. Caps are unchanged.

## Standard basis and GNU limitations

J3/18-007r1 section 7.8 paragraphs 2, 5, 8, printed p89 (PDF p104):
https://j3-fortran.org/doc/year/18/18-007r1.pdf . Without a type specification,
matching ac-value length parameters supply the constructor parameter. A zero
sequence does not silently erase a descriptor-known length. Descriptor inquiry
is distinct from consuming a nonconstant CHARACTER value or depending on the
implied-DO index.

GNU 14.2 is not a universal empty-length execution oracle. `gnu-semantics.json`,
`probe/` and retained first results show context-sensitive zero lengths despite
known nonzero descriptors, plus a nested empty constructor rejected as not
CHARACTER. These fixtures retain independent expected lengths and compile-only
or explicitly pinned compiler-rejection stages. Expected lengths were not changed
to match GNU zero results. Runtime-invalid sources are never executed by GNU.

## Strict harness and reproducibility

```
python tests/dynamic_character_constructor/run_tests.py --candidate PATH --gfortran gfortran
python tests/dynamic_character_constructor/self_test.py
python tests/dynamic_character_constructor/check_generator.py
```

The standalone runner accepts `--original-source PATH`; the installed default
is `../utilities_slices/source/xutilities.f90`. All formatted/CHARACTER output is
byte-exact, including blanks and record endings. Successful stderr and check
stdout must be truly empty. The optional numeric comparator uses exact Decimal,
distinguishes signed zero, preserves large integers, supports D/E exponents and
rejects nonfinite values. Every negative stage requires its exact status, path,
line, column and diagnostic. Unpinned diagnostics fail closed.

All 48 adversarial harness checks and 74-file generator replay pass (72 source
files, manifest and provenance). Two native programs under `test/` pass 111
assertions: 36 public-IR/runtime and 75 independent source-adapter checks.
`native-final-second-results.json` records the complete FPM debug flags and
library/binary hashes. No full native aggregate was run in this feature lane.

## Retained development evidence

`candidate-second-gnu-results.json` is the final 72-case receipt. Initial GNU
anomalies, unpinned diagnostic failures and prior 69-case metadata remain under
`initial-evidence` and named first-run receipts. Three new fixed-length
unallocated LEN regressions fail on candidate-first and pass candidate-second;
`candidate-first-fixed-regression-results.json` records that narrow regression.

Initial native failures were corrected new-fixture assumptions: missing required
INTENT, procedure-root selection and expecting ordinary-leaf diagnostic-position
identity rather than semantic binding checks. Initial native sources and logs
remain; all earlier binaries are retained in the development workspace. Final
native guards additionally execute malformed constructor bodies to verify safe
runtime rejection. No old Fortran fixture body was changed.
