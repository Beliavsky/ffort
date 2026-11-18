# Independent 0.52 gather compositions

Twenty small synthetic sources combine rank-one CHARACTER gathering with DO WHILE
condition/body refresh, INTEGER8 masks and shifts, rank-three element internal
WRITE, allocation and alias snapshots, output/constructor implied-DO controls,
empty/deferred descriptors, CHARACTER MAX padding, and module-derived fields.
They are not upstream utility originals and do not establish full-library support.

`run_tests.py` checks exact UTF-8 record bytes, including embedded/trailing blanks
and final newlines. Numeric results use explicit INTEGER edit descriptors and are
also byte exact; no float coercion or tolerance is used. Successful `--check` must
be silent. Rejections pin stage/status, full source path, line, column, and message;
crash/trace/ICE signals and unexpected output are rejected. Compile-only GNU cases
are not executed. Candidate and source identities are checked before/after the
run; candidate `--version` is checked when `--expected-version` is supplied.

Run from the project root:

```sh
python tests/release052_integration/test_runner.py
python tests/release052_integration/run_tests.py --candidate /path/to/interpreter --expected-sha256 SHA256 --expected-version VERSION --gfortran /path/to/gfortran
```

Omit `--candidate` for GNU-only preparation. `--observe` deliberately records
candidate output without asserting candidate expectations; it is not a passing
candidate contract and is never used in the aggregate verifier hook.

The generator reproduces every maintained fixture and manifest byte. First
sources and oracle failures are preserved in `oracle-evidence`; `provenance.json`
records expectation-only corrections. The original 18 source hashes remain
unchanged. Main-local TYPE declarations, dynamic untyped gather constructors,
bare same-base writable actual aliases, and reached internal slash descriptors retain
explicit bounded evidence; separately named supported forms are not rewrites.

Pending-output failures prove exact preservation of previously emitted `SAFE`
without a new partial output record. They do not independently observe internal
file storage after a terminating error; target commit safety has separate native
coverage in the owning feature suite. This suite does not stress allocation caps.

The direct derived-component selector in a CHARACTER gather is retained separately
from its scalar-staged success. The corresponding numeric rank-two gather succeeds
on both certified 0.51 and the first 0.52 preview, so the CHARACTER failure must not
be described as an inherited numeric restriction. The feature owner explicitly retains this as a new bounded CHARACTER-selector
exclusion for this checkpoint. It is a GNU-valid rejected program, not a claimed
language error or regression in the older numeric gather path. No global KIND
walker expansion is part of this feature.

The additive bare-actual feature advances the preserved
`unparenthesized_actual_boundary` source from a static parentheses rejection to
an exact runtime whole-base alias rejection. Its sibling OUT actual is the same
allocatable array, so this source is not promoted to execution success. The
parenthesized snapshot counterpart still succeeds. The first c750 contract and
first ed6 observation are retained separately; the metadata migration changes no
Fortran bytes and does not execute this alias-boundary program with GNU.
