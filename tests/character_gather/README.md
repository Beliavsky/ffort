# Rank-one CHARACTER vector gathering

Adds read-only gathering from default-kind, non-POINTER rank-one CHARACTER arrays
using one rank-one INTEGER index vector. Repeated indices, nonunit lower bounds,
empty/zero-length results and assumed/deferred lengths follow array descriptors.
Parenthesized values can be passed to INTENT(IN) dummies and are copied before a
second aliased allocatable actual is deallocated/replaced.

Scope stays narrow: CHARACTER rank-two/three gathers, scatter and new
WHERE/FORALL gathering remain excluded. Numeric rank-one gathering is a separate
extension and does not change this suite's CHARACTER descriptor contract. In the integrated 0.52 contract, a bare gather
is admitted only to an ordinary non-TARGET, non-POINTER, non-ALLOCATABLE,
non-CLASS assumed-shape INTENT(IN) dummy. It retains whole-base identity for
conservative writable/host alias checks; even disjoint or empty selections
conflicting with a writable same-base actual are rejected. Parenthesized values
retain independent snapshot semantics. See
[the current CHARACTER contract](../../docs/CHARACTER-GATHER.md) and
[bare actuals](../../docs/BARE_CHARACTER_GATHER_ACTUAL.md).
Dynamic-length untyped CHARACTER constructor nesting remains a CHECK rejection;
explicitly typed constructors and fixed-length untyped constructors are covered.

Gather string caches have a16MiB aggregate per-frame resident-payload admission
limit plus existing element limits. Per-cache charges are released on invalidation,
including implied-DO iterations. This is not a whole-process heap bound. Selected
string metadata and definedness are checked before the gather's payload copy.

## Historical isolated first-preview validation

Reconstructed against released0.51 b39586e7; fresh independent source review passed
7ada416e. No pre-reset review or test result was treated as validation of these bytes.
Preview0.52 CLI c75015954df558fe895150dfefb8feac59c379ae8e136e89f2f5bf7a5779021e
passes24 strict cases,16 harness tests and113 extended native assertions.
GNU compiled24 sources, executed17, and seven boundaries remain compile-only.
601 nearby unchanged historical source cases pass; no historical promotions needed.
Central nearby native tests are recorded separately in evidence, not added to the
113-assertion count. Windows execution has not been tested.

The original utilities select_vec_character/set_alloc_character_vec/
set_optional_integer bodies are preserved with normalized line endings in the
original_dependency_closure fixture; only generic wrappers, constant declaration
and driver are tailored. This passes both optional-idim paths and alias resizing.
At that isolated c750 first-preview stage, the complete adapted utility advanced
to 2523:31, its then-unsupported bare xx(iuse) actual. The integrated read-only
bare-actual feature closes that gate without changing the call. At integrated0.52, full
working-source checking rejected at 2678:36 on a rank-one INTEGER gather;
the untouched original retains its independent 9329:55 cap boundary. The0.53 numeric extension advances the unchanged working source to2992:1 INQUIRE. Neither
stage claims that the whole utilities module runs.

From the `tests/character_gather` directory, run `python3 tests/test_contract.py`, then:
`python3 run_strict.py --candidate /path/to/ffort --expected-sha SHA256 --gfortran /path/to/gfortran --output results.json`
The generator is self-contained and source identities are pinned. Every failure
contract fixes phase/status/path/line/column/message with empty stdout; text is
byte-exact, only explicit integer-only records allow field padding.

## Additional composition boundary

Direct derived-component selectors, for example CHARACTER x([r%n,1,r%n]), are valid Fortran but remain an explicit exclusion in this checkpoint: CHECK succeeds and execution rejects with 'invalid KIND argument opcode'. This is a CHARACTER-gather metadata-length-path limitation, not an inherited numeric-gather restriction; the numeric rank-two counterpart succeeds on both 0.51 and this preview. Assigning n=r%n first and selecting with n works. The exact original select_vec_character dependency closure is unaffected.

## Later strict-harness extension

The 16-test count above describes the preserved first isolated stage. The later
strict runner uses explicit identity guards under optimized Python and checks exact returned record count/name/source/hash/mode bijection before outcome reduction. It has 28 harness tests, including subprocess corruption controls; no separate version argument is added because the candidate is hash-pinned.

## 0.53 numeric rank-one migration

The unchanged `numeric_rank1_boundary.f90` now executes. Candidate stdout is exactly ` 3 1\n`; GNU stdout is separately pinned exactly, including its list-directed field spacing. The generator mode was updated without changing source bytes. These measured updates supersede the earlier rank-one rejection boundary; all other suite policies remain unchanged.

## current progression

Historical 0.53 checkpoint: The 0.53 numeric rank-one extension advances the byte-preserved adapted working source to 2992:1, `INQUIRE`. This is still a source-stage rejection, not interpreted whole-program execution. The untouched original retains its 9329:55 resource-cap rejection. INQUIRE is excluded from this checkpoint; no file-access or ordinary-function effect policy is relaxed. See [numeric gathering](../../docs/NUMERIC-VECTOR-GATHER.md).

## Current bounded input-name inquiry

The focused 0.54 composition adds only [registered input NAME inquiry](../../docs/INQUIRE_NAME.md). The byte-preserved adapted working source now stops at 2995:41 on external READ to a CHARACTER array element; the untouched original still stops at 9329:55 under the unchanged array cap. Both remain pre-execution source rejections. See the [working-source evidence](../utilities_working/README.md). READ-element support remains outside this checkpoint, and no host-unit discovery, general file access, writable-actual or ordinary-function effect relaxation is implied.
