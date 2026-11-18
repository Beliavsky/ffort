# MASKL / MASKR / SHIFTR focused verification

Historical 0.50 corrected combined preview: 164 contracts pass, comprising 113 successful
programs, 30 exact static boundaries and 21 exact runtime guards. GNU independently
executes 125 programs, compiles 21 without executing undefined/out-of-range
inputs, and rejects 18. CLI before/after SHA256:
`3e9c191de0f548e9dc8fc189c3d579e4fde4dbc2617c0b43170add660ca04a19`.

At that recorded checkpoint, original MASKL and MASKR match every GNU byte. Original SHIFTR fails its
unchanged ISO INT8/INT16 import boundary; actual INT8 and BOZ usage are not
implemented by this feature. Native public-IR/value tests pass 5,747 assertions;
old bit/producer/LEADZ regressions also pass. Full release certification is separate.

Reproduce strict source/GNU validation:
```
python3 tests/integer_masks/run_tests.py --candidate /path/to/cli --expected-sha256 SHA --gfortran /path/to/gfortran --result tests/integer_masks/results.json
python3 tests/integer_masks/test_contracts.py --evidence tests/integer_masks/results.json
python3 tests/integer_masks/verify_registry.py
```
For recorded evidence only, run `test_contracts.py` with its default corrected
result. `test_output_contracts.py` tests synthetic stage/record mutations without
executing a compiler/interpreter. GNU reference binaries are discarded by
default; --retain-gnu-binaries retains them locally for debugging, never in the
source release. Exact failing diagnostics are already pinned. --observe is only
for first diagnostic collection and cannot certify failure contracts.

The initial 136 GNU/source contracts, first146 candidate sources/expectations,
all raw failures and manifests are preserved. Six first expectations crossed
the inherited rank-three RESHAPE boundary: those source bodies remain unchanged
and their first failures remain visible. Six separate ordinary-assignment rank3
variants and twelve separately named mixed-kind PARAMETER conversion cases were
added. first-stage-classification-mapping.json records the exact mapping.

The initial native PARAMETER cached-kind mutation failure is retained in
native-evidence/first. The identical source passes after the narrow bit-tree
parameter guard; no native expectation was weakened. Initial unbuilt oracle
source and its independent signed-overflow endpoint correction are retained in
the feature handoff history.

Ordinary integer/logical output uses exact per-record tokens; only horizontal
ASCII space widths may vary. Original MASKL/MASKR use full-byte comparisons.
Checks have empty stdout/stderr; successful runs have empty stderr. Failures
require exact source path, line/column, one-line message, phase and exit status,
with no timeout or crash markers. GNU undefined/invalid value calls never run.

Initial GNU-only evidence erroneously labeled certifies_exact_negative_contracts
true in one early runner. identity=null/raw commands prove no candidate ran;
gnu-only-audit.json explains the correction without modifying initial evidence.

## 0.53 import progression

The separate [TRAILZ/ISO availability contract](../../docs/TRAILZ-ISO-INTEGER-AVAILABILITY.md) exposes INT8/INT16 as -1 and INTEGER_KINDS=[4,8], not host kinds or small-kind storage. SHIFTR remains a full-example boundary despite advancement beyond its old import rejection; exact diagnostic migration requires measured evidence. The historical counts and CLI identity above are unchanged.
