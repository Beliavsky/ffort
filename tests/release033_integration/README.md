# Release 0.33 independent composition checks

Fourteen cases combine bounded PURE specification functions and initialized
local SAVE state with existing recursion, explicit-shape dummy association,
POINTER views, array expressions, WHERE, reductions, and exact INTEGER(8) values.
The corpus has seven successful executions, two runtime-policy checks and five
source boundaries. Literal expected outputs were written independently of both
implementations before the GNU or candidate run.

## Executed combinations

- Five exact original utility bodies (`factorial_long`, `choose`,
  `few_combinations`, `default_logical`, `gen`) run together. A separate synthetic
  driver sizes local matrices with `choose`, compares `gen` against the original
  array-result `few_combinations`, observes retained recursive `icomb` state, and
  resets it for different and empty extents. This is not full xutilities execution.
- Recursive calls share saved INTEGER/CHARACTER values while each activation
  retains its own spec-sized array, frozen CHARACTER length and local contents.
- A saved call counter modifies a spec-sized automatic workspace, then writes
  through arithmetic explicit-shape TARGET dummies. Strided and reversed actual
  prefixes copy back to live main-program pointers without changing unused tails.
- An IMPURE ELEMENTAL function advances its saved counter once per element of a
  spec-sized automatic array. An intervening empty invocation advances only the
  enclosing subroutine's saved count. WHERE and reductions observe the result.
- A saved scalar is passed through an INOUT dummy used in a PURE specification
  call that reads module data. Changes to both input and module state do not
  resize the current frame; subsequent calls see the new values.
- INTEGER(8) specification inputs/results compose with saved values above 2^53;
  output comparisons use exact integers rather than binary floating-point.
- A parenthesized saved actual is an input snapshot across recursion, while
  spec-sized automatic locals retain activation-local contents.

## Boundaries and safety

Four cases are GNU compile-only, not GNU execution oracles:

1. A mathematically empty array still evaluates its specification function and
   consumes the shared execution budget before the saved-state body starts.
2. A specification-produced extent exceeds the interpreter's element limit
   before the body can mutate its saved counter or emit output.
3. A direct saved actual is rejected when the callee's recursive call graph can
   reference the same saved symbol. The passing snapshot case is distinct.
4. User-function calls remain outside the existing explicit-dummy bound grammar.
   The passing pointer-prefix case uses an arithmetic dummy bound and a separate
   automatic workspace sized by a specification function.

Three additional sources are rejected by both GNU and the candidate: SAVE inside
an otherwise eligible PURE specification function, a user function in a SAVE
initializer, and SAVE on runtime-length CHARACTER. Empty-array syntax does not
bypass purity validation. No source boundary is relabeled as a successful
execution, and no undefined or resource-policy case is executed by GNU.

## Original source provenance

`original/combinations_module.f90` has a new module wrapper, kind parameter and
`default` generic interface. All five bodies retain their exact original bytes,
including CRLF and comments. `cases/original_combined_driver.f90` is separate and
wholly synthetic. The runner concatenates support source and driver bytes only
inside fresh temporary directories for each compiler/candidate invocation.

`original-source-map.json` records original and wrapper offsets, source line
numbers, per-body SHA-256, and whole-source and wrapper fingerprints. Its ranges
include each terminal CRLF; the standalone specification-function suite excludes
that final CRLF for the first three functions, explaining their different hashes. The runner
checks every byte range before and after testing. The original full source is
`../utilities_slices/source/xutilities.f90`, with SHA-256
`c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`.

## Runner

From the repository root:

```
python3 tests/release033_integration/test_runner.py
python3 tests/release033_integration/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran gfortran
fpm test --target test_release033_composition
```

GNU flags are `-std=f2018 -pedantic-errors -fcheck=all,no-array-temps -O0`.
Only the expected noncontiguous-actual temporary warning is suppressed; other
runtime checks remain enabled and all execution stderr fails the oracle.
Every program compiles in a fresh directory. GNU is an oracle, never a candidate
execution backend.

The runner checks strict exit classes, diagnostic content, missing diagnostics,
stdout leaks, crashes/timeouts, exact integers, finite reals, differential output,
and source/manifest/provenance integrity. It uses a private executable snapshot,
checks source and copy hashes around copying, and rejects empty/nonexecutable
mid-link captures before case evaluation. A version probe validates the snapshot.
Twenty-one runner self-tests include build-race and exact original-body checks.

## Native composition checks

`test/test_release033_composition.f90` combines recursive saved integer and
CHARACTER state, spec-sized arrays/lengths, explicit-dummy copyback and live pointer
observations in one program. Every mutation begins with a fresh parse, independent
adapter validation, and successful execution. Twelve corruptions are checked
separately by the adapter and direct runtime, for 24 rejections. They include
crossing dynamic-bound and constant-initializer metadata, making a mutable saved
local a specification actual, corrupting fixed saved CHARACTER length metadata,
forging PURE/result ownership, and cyclic bound-expression arguments.

Three repeated-root checks establish fresh SAVE and pointer state with immutable
initializer caches. A measured, one-step-short execution fails after state was
already changed; the same IR then executes successfully with fresh state. This
adds two checks, for 29 total. This direct native test supplements rather than
replaces the source-level GNU comparisons.

`results.json` records the candidate/GNU corpus evidence. `verification.json`
records runner and native execution evidence and existing-fixture preservation.
These focused checks are not a claim that the entire release verifier passed;
the release owner runs that separately on the final tree.
