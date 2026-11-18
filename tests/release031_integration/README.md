# Release 0.31 bounded composition checks

This suite contains 13 synthetic fixtures and one minimal wrapper of original
`variable_names`. The synthetic fixtures combine TARGET declarations with
LOGICAL allocatables, SHAPE/FINDLOC, descriptor dummies, OPTIONAL forwarding,
CHARACTER element LEN specification expressions, noncontiguous sections,
recursion, scalar REPEAT and literal CHARACTER substrings. TARGET does not
implement POINTER association or pointer lifetime semantics.

## Run

From the repository root:

```sh
python tests/release031_integration/test_runner.py
python tests/release031_integration/run_tests.py \
  --candidate /absolute/path/to/fortfront-interpreter \
  --gfortran /absolute/path/to/gfortran
fpm test --profile debug --target test_release031_composition
```

Either processor can be selected independently. `--only REGEX` selects fixtures;
`--result FILE` changes the report path, relative to this directory unless it is
absolute. GNU-only evidence is reproduced with:

```sh
python tests/release031_integration/run_tests.py \
  --gfortran /absolute/path/to/gfortran --result gnu-results.json
```

The additions for `scripts/verify.py`, after resolving `exe` and `compiler`, are:

```python
run([sys.executable, 'tests/release031_integration/test_runner.py'])
run([sys.executable, 'tests/release031_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
```

This suite does not edit aggregate scripts or core sources. The ordinary
`fpm test --profile debug` aggregate discovers the native test through the
repository's `auto-tests = true` setting.

## Cases and independently reasoned outputs

All expected outputs are literal manifest entries. GNU and the candidate must
independently match them; GNU execution output must also match the candidate.
Formatted CHARACTER lines require exact spaces, including trailing padding.

The ten successful execution cases are:

1. `target_optional_logical_descriptor`: forwarding an omitted OPTIONAL TARGET
   descriptor differs from a present unallocated one. Allocation preserves
   bounds `(-2,5,9)` and shape `[2,2,1]`. A rank-reduced WHERE gives sums 21 and
   31 before and after inversion; FINDLOC sees the expected matrix coordinates.
2. `target_character_descriptor_lengths`: rank-three TARGET CHARACTER actuals
   supply length 5 and then length 7 to automatic rank-two locals through
   `LEN(x(1,1,1))`. The second array has no elements. FINDLOC respects allocated
   LOGICAL TARGET masks and returns zero coordinates for the empty array.
3. `target_section_copyback_search`: a reversed stride-two TARGET actual is
   updated through a TARGET assumed-shape dummy, including a LOGICAL mask.
   Copyback produces `[1,13,3,14,5,17]`; searches use section element positions.
4. `target_recursive_descriptor_result`: a TARGET LOGICAL allocatable function
   result is assigned and recursively mutated through a TARGET allocatable
   dummy. Each plane ends with one true element at coordinate `[1,2]`.
5. `target_optional_character_search`: two forwarding levels preserve absent
   versus present OPTIONAL TARGET CHARACTER, assumed lengths and an allocated
   mask. Searches of the present value find positions 1 and 3.
6. `target_logical_reallocation_bounds`: same-shape assignment preserves lower
   bound -3, size-changing assignment adopts source bound 8, and TARGET
   allocatable INTENT(OUT) deallocates on entry before new allocation and reset.
7. `target_repeat_character_filter`: scalar REPEAT inside a TARGET CHARACTER
   array-result function doubles each padded three-character element. The
   result length is six; masked FINDLOC chooses positions 1 and 3. Exact padded
   strings `ab ab ` and `cd cd ` are checked independently.
8. `target_repeat_optional_recursive`: OPTIONAL forwarding guards an integer
   repetition depth. Three recursive calls repeatedly double a trimmed scalar
   TARGET CHARACTER argument, producing exactly `xxxxxxxx`.
9. `target_literal_repeat_composition`: runtime and constant literal-substring
   bounds feed REPEAT, TARGET array assignments, LEN and masked FINDLOC. The
   resulting values are `1212`, `2323`, `1212`; the last selected match is 3.
10. `variable_names_original`: original `variable_names` runs with all optional
    fields, absent optional fields and zero extent. Labels are `v-2_x`, `v-1_x`,
    `v0_x`, `v1_x`, then default `1`, `2`; the empty result retains length 100.

## Exact original bodies, not full module execution

`provenance.json` identifies the retained `../utilities_slices/source/xutilities.f90`
source by SHA-256. `cases/variable_names_original.f90` includes these bodies,
byte-for-byte including their original CRLF line endings:

- `variable_names`, source lines 2078–2094: the one newly covered original utility.
- `str_int`, lines 2096–2118: unchanged dependency. Its standalone utility fixture
  and additional options belong to the separate REPEAT feature suite, not new
  independent utility coverage here.
- `default_integer`, lines 3699–3709: unchanged dependency, not new standalone
  utility coverage.

The minimal module, the one-specific `default` generic interface, and driver are
synthetic. The wrapper does not execute the full original module or preserve its
entire overload set. REPEAT and literal-substring resolution are required to
compile `str_int`; `variable_names` calls it without NDIGITS, so the original
zero-padding REPEAT branch is not reached by this wrapper. Separate synthetic
joint cases execute REPEAT. The original full-file POINTER gate remains outside
this suite.

The runner checks complete source/wrapper hashes, source line spans, wrapper byte
spans, exact byte equality and per-body hashes before and after verification.
Reformatting or normalizing the retained bodies fails provenance validation.

## Boundaries, without inflated GNU pass counts

- `target_pointer_remains_unsupported`: GNU **compile-only**, candidate source
  rejection (exit 1), and the unsupported-declaration diagnostic. Valid GNU
  POINTER association is not an interpreter feature.
- `target_parameter_conflict`: GNU syntax rejection and candidate source
  rejection (exit 1). The unchanged TARGET/PARAMETER combination is invalid.
- `target_mask_runtime_shape`: invalid nonconforming FINDLOC MASK. Candidate
  check succeeds; execution returns runtime failure (exit 2), the specific
  conformance diagnostic and no stdout. GNU is explicitly **skipped**.
- `target_repeat_runtime_negative`: invalid runtime negative NCOPIES. Candidate
  check succeeds; execution returns runtime failure (exit 2), a REPEAT
  diagnostic and no stdout. GNU is explicitly **skipped**.

No invalid runtime input is used as a GNU execution oracle. Compile-only checks,
shared source rejections and explicit policy skips are not differential runs.

## Isolation and runner self-tests

The runner makes a private hashed candidate snapshot. GNU compilation/execution
and candidate checks/runs use fresh temporary directories, so stale executables
and module files cannot satisfy a case. Reports retain exact command vectors,
working directories, tool versions, source/manifest/candidate hashes, compiler
flags, exit status, stdout and stderr. Source/manifest/snapshot hashes are checked
again afterward. Successful cases reject any stderr, and all failure cases
require the precise exit class, diagnostic and absence of leaked output.

The 16 runner self-tests cover exact wide integers, finite Decimal comparisons,
nonfinite output, mismatches, CHARACTER padding, exit classes, missing diagnostics,
output leakage, source-path diagnostic false positives, missing provenance and
CRLF normalization. These are test-harness checks, not language cases.

## Native composition and metadata checks

`test/test_release031_composition.f90` combines seven TARGET array/dummy symbols,
LOGICAL rank-three allocation, OPTIONAL forwarding, assumed CHARACTER lengths,
automatic rank-two CHARACTER storage and rank-reduced masked FINDLOC with KIND=8.
It checks successful adapter/runtime execution and repeated execution reset.

Twelve deliberate metadata corruptions require both adapter and direct-runtime
rejection: allocation third-axis operand, LOGICAL kind, LEN element third
subscript and out-of-range subscript ID, length/scope metadata, MASK type/rank,
VALUE rank, result extent/kind and a cyclic VALUE argument. Nine per-symbol TARGET
flag changes require adapter rejection; an impossible PARAMETER+TARGET flag also
requires runtime rejection. Total: **34 metadata rejection assertions**. Legal
TARGET metadata alone is not treated as requiring pointer lifetime semantics.

`native-target-results.json` records a fresh standalone compile/link against the
initial TARGET-only merged 0.31 library, with source/library SHA-256. This is
explicitly pre-final-build evidence. Final clean `fpm test` results remain the
authoritative native aggregate evidence.

## Recorded evidence

- `target-checkpoint-results.json`: nine TARGET-only candidate checks/runs pass;
  GNU supplies six executions, one compile-only check and one syntax rejection;
  one runtime guard skips GNU. This is explicitly earlier TARGET-only evidence.
- `gnu-results.json`: all 12 GNU checks pass, comprising ten executions, one
  compile-only check and one syntax rejection. Two runtime guards explicitly
  skip GNU. Zero case failures and zero integrity failures.
- `results.json`: all 14 merged cases pass with zero integrity failures after
  TARGET, REPEAT, literal substrings, bare DO and token-kind-aware operators are
  combined. GNU supplies ten execution comparisons, one compile-only boundary
  and one syntax rejection; two runtime safety guards skip GNU. The exact
  original variable_names body and its unchanged str_int/default_integer
  dependencies execute successfully with raw CRLF provenance checks. No original
  procedure was rewritten to bypass a parser boundary. Final clean archive
  verification reruns this evidence against the exact shipped implementation.

## Promotion in release 0.32

The unchanged source named target_pointer_remains_unsupported is now a successful
bounded pointer test; its historical filename remains for source preservation.
The current manifest therefore has eleven GNU executions, one GNU source
rejection and two skipped runtime guards. Earlier receipts above describe 0.31,
while results.json is regenerated for the current candidate.
