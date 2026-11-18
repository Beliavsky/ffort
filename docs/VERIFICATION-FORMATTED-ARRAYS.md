# Formatted-array verification

The implementation and checks were run on Linux with GNU Fortran 14.2.0 and
fpm 0.13.0 alpha, starting from the 0.23.0 source archive. This is focused feature
verification, not a claim to have rerun every Python corpus in the package.

- The complete native `fpm test` suite passed, including the new formatter test.
- The formatted-array differential/fail-closed suite passed all 47 cases.
- Existing numerical-procedure suite: 88/88 candidate cases, 85 GNU cases,
  three documented GNU skips.
- Existing derived-type suite: 43/43 candidate cases, 38 GNU cases, five skips.
- Existing CLASS/type-bound/defined-I/O suite: 44/44 candidate cases, 40 GNU
  cases, four skips.
- Existing array-limit suite: 30/30 cases.
- `git diff --check` passed.

The new suite includes the unchanged upstream M_intrinsics DOT_PRODUCT example
(SHA-256 `8e1bed4b92f47c08e92f7e9b891885aca7cd689e2c8cc4349c1ec5839842fd63`).
GNU output matches every formatted and empty record exactly. Its final
list-directed value is 32 in both implementations, compared without requiring
processor-specific integer field padding. `--check` succeeds without stdout.

The native test checks rank-two internal WRITE and PRINT, seven independently
mutated AST/IR disagreement rejections, three malformed-IR runtime format
rejections and six direct validator boundaries. Differential cases cover every
supported intrinsic format family, both numeric kinds, CHARACTER, LOGICAL,
rank-two order and reversal, sections, constructors, PACK, array results,
assumed-shape dummies, internal writes from functions, defined child writes,
zero-sized arrays, partial final records, trailing X/literals and I0.0 zeros.

Negative cases require the expected compile/runtime status and empty stdout:
wrong item types, later-cycle mismatches, undefined elements, recursive output,
missing data edits, format groups/slash/dynamic formats, single-record WRITE
exhaustion, invalid repeated literal syntax, expanded-value limits, aggregate
output size, and bounded format traversal. The zero-width CHARACTER test also
exercises 65,536 distinct records without exhausting the bound.

Windows execution has not been verified. The full aggregate verifier is updated
to include this suite, but release integration should still run it on the final
combined source tree.
