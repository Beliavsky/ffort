# Independent ELEMENTAL subroutine / IMPURE procedure corpus

The generator is independent of interpreter modules and records exact output
values, categories, CLI exits and selected diagnostics. Recreate the fixtures
with `python3 generate_cases.py`. Run `python3 test_runner.py` to validate runner
failure detection and byte-for-byte reproducibility.

```
python3 run_tests.py --candidate /path/to/fortfront-interpreter --gfortran gfortran
```

The retained 128 cases cover scalar and rank-one/rank-two calls, all supported
prefix orders, IN/OUT/INOUT flags, scalar expansion, type/kind checks, keyword
permutations, 16 rank-two stride combinations, overlap and expression snapshots,
empty arrays, module/assumed-shape composition, pure-call restrictions, ordered
impure PRINT effects, function materialization/cache lifetime, masks, products,
recursion-safe I/O rejection and shared work limits.

The candidate is checked twice per fixture: `--check` must not emit output,
then execution must produce the independently specified outcome. GNU compiles
with `-std=f2018 -pedantic-errors -fcheck=all -O0` in a fresh temporary directory.
Check and run diagnostics/statuses are recorded separately. Source/manifest and
candidate binary hashes are included in result JSON.

For this corpus the applicable GNU checks comprise 81 executions, 12 compile-only
checks and 17 expected compilation rejections. Three checks use weakened
SIMPLE-to-PURE references, explicitly labeled rather than claimed as native
SIMPLE evidence. Eighteen interpreter-policy cases skip GNU altogether.

Important distinctions:

- The standard's whole-reference overlap restrictions are independently checked;
  compiler behavior for an invalid aliased/undefined program is not an oracle.
- GNU 14 accepts the all-IN elemental array subroutine and duplicate IMPURE
  negatives. These are compiler-compilation evidence only; their rejection
  expectation comes from independent source rules.
- GNU can interleave nested impure references and omit masked function elements.
  The prototype's full materialization order is tested independently. Those
  fixtures are compile-only, not claims of matching GNU side-effect output.
- A scalar function assigned to a zero-sized array follows this prototype's
  explicit once-only expansion policy, not a GNU execution guarantee.
- A section-shape mismatch can be rejected statically by GNU but at runtime by
  this interpreter. The runner keeps compiler and candidate outcomes separate.
- The historical `runtime_active_loop_scalar` fixture name is retained, but its
  category is invalid because both compilers reject it before execution.

The full supported contract and primary source links are in
[docs/ELEMENTAL-SUBROUTINES.md](../../docs/ELEMENTAL-SUBROUTINES.md).
