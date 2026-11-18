# Numeric rank-one vector subscripts

## Bounded support

A named non-POINTER INTEGER(4/8) or REAL(4/8) rank-one array accepts one rank-one INTEGER(4/8) vector selector, including lower bounds, repeated and reordered indices, empty selections, allocatable results and self-assignment/reallocation. The existing gather path evaluates selector elements once, bounds-checks them, then snapshots selected values before target updates. Selected uninitialized elements, unallocated bases and malformed metadata fail explicitly. Empty value selections do not excuse an unallocated base. Numeric KIND is metadata-only; SIZE retains the existing eager gathered-value boundary.

No element, temporary, storage or execution limit is increased. Index and gathered-result temporaries share the configured element/cache admission checks. A focused case preserves the default execution-budget failure; a separately named identical source uses explicit100m to reach the element-temporary limit. This does not change the default budget.

Bare numeric gathered actuals are admitted only for ordinary rank-one assumed-shape INTENT(IN) dummies of exactly the same type and kind. ALLOCATABLE, POINTER, TARGET, CLASS, explicit-shape and writable dummies remain excluded. Bare gathered calls to ELEMENTAL scalar dummies also remain outside this ordinary assumed-shape contract; use a supported parenthesized value instead. Bare gathers conservatively retain their entire base against writable and host/USE aliasing, even for empty or disjoint selections. A parenthesized snapshot remains the explicit safe form for same-base output/reallocation. The independent producer-token check verifies parentheses for both CALL and FUNCTION applications.

Existing default-kind CHARACTER gathers, byte limits and alias semantics remain unchanged. Numeric rank-two gathering remains row-only; numeric rank-three gathering remains one vector axis with bare colons elsewhere. No LOGICAL/pointer-base/scatter or external-effect support is added.

## Exact utilities and boundaries

The complete CRLF bodies of `unique_vec_int`, `unique_int` and `set_alloc_int_vec` are preserved with source hashes; only module/generic scaffolding and drivers are synthetic. Exact standalone `unique_int` (including empty input) and recursive `set_alloc_int_vec` execute against GNU. Full `unique_vec_int` closure sources remain explicit GNU-valid compile boundaries because the ordinary-function policy rejects the transitive external-WRITE error branch in `unique_int`. That policy is unchanged, not bypassed by test rewriting.

On immutable0.53 preview `1be6387254cc8dfe789537149ffbf74e88b9f020097627871606caa3af210bc9`, the exact user-authorized nmax=100000 working source advances to2992:1 INQUIRE. The untouched original retains its independent excessive-array declaration boundary at9329:55. No whole-utilities execution is claimed. Windows execution has not been tested.

## Validation and retained first failures

- 98 focused source/GNU contracts:56 candidate successes,28 compile boundaries,14 runtime boundaries;69 GNU executions,22 GNU compile-only cases,7 GNU constraint rejections.
- 480 observed central native assertions bind the exact matching library/profile and cover producer/source identity, all four numeric kinds, independent adapter/runtime mutations, KIND/empty cached-wrapper safety, alias policy and execution reset after budget failure.
- 25 Python harness methods pass normally and under `python -O`.102 generator outputs are byte-identical in optimized-mode replay.
- Historical66 row-gather,122 rank-three and24 CHARACTER-gather cases pass after separate measured metadata-only migrations. All prior Fortran source bytes remain unchanged.

The first89 source run is retained. Eight GNU-valid synthetic RESULT(out) sources expose an inherited reserved-name parser boundary, confirmed on released0.52; eight separately named result_value controls test the intended function-actual path successfully. Five original full-function closures retain the effect boundary above. The first native source assumed an array_slice AST for rank-one gathering; a separate producer observation proved call_or_subscript at the exact location. The corrected native binds name, location, array-access flag, selector count/type/kind and result rank/type/kind, rather than weakening the oracle. Its historical source-only header is kept so the compiled source hash stays exact.

StrictUTF8 output handling exposed four earlier GNU-diagnostic pins decoded as latin1; the exact UTF8 strings were corrected without loosening comparison. The INTEGER8 processor-minimum fixture is explicitly an extension probe with exactly two pinned GNU symmetric-range warnings. Earlier policy hashes, outputs and correction deltas remain in evidence.

## Reproduction

From `tests/numeric_vector_gather`:

```
python3 test_runner.py
python3 test_contract.py
python3 -O test_runner.py
python3 -O test_contract.py
python3 run_tests.py --candidate /absolute/ffort --expected-candidate-sha256 SHA256 --candidate-version 0.53.0 --gfortran /absolute/gfortran --evidence-dir /new/evidence --result /new/results.json
python3 generate_cases.py --upstream ../utilities_slices/source/xutilities.f90 --output /new/generator-replay
```

Result/evidence paths must not already exist. The runner retains exact raw stream bytes, hashes and strictUTF8 status; timeout, signal and spawn failures remain distinct. Successful streams and negative stage/status/path/line/column/message are exact. Expected candidate SHA/version is checked before the first source invocation; compiler and full suite-policy/source identities are checked again afterward. Unknown schemas, duplicate or missing cases, unpinned diagnostics, crash markers and changed source bytes fail closed even under optimized Python. No blanket numeric or whitespace comparison is used.

## Current input-name checkpoint

The immutable 0.53 observation above is retained as historical evidence. With
[bounded registered-input NAME inquiry](INQUIRE_NAME.md), the focused 0.54
adapted-source gate is 2995:41, external READ to a CHARACTER array element.
The untouched original retains the 9329:55 cap boundary. Neither source begins
whole-program interpreted execution. READ-element support and ordinary-function
effect-policy relaxation remain outside this checkpoint.
