# FortFront 0.53.0: numeric rank-one gathering and TRAILZ

This is a verified source checkpoint: the clean maintained aggregate and independent source/output audit passed. It remains a deliberately bounded prototype, not full Fortran or whole-library support.

## Bounded additions

Named non-POINTER INTEGER/REAL kinds 4/8 rank-one arrays support rank-one INTEGER kinds 4/8 vector selectors. Selected values are bounds-checked and snapshotted before assignment or reallocation; repeated order, lower bounds, duplicate indices and empty results retain the documented allocation/definedness rules. KIND remains metadata-only, while SIZE retains its eager gathered-value boundary. See [numeric vector gathering](NUMERIC-VECTOR-GATHER.md).

Bare numeric gathers may associate only with matching ordinary rank-one assumed-shape INTENT(IN) dummies. Whole-base writable/host/USE alias reservations remain conservative, including empty/disjoint selections. Parenthesized value snapshots remain distinct, with independent producer-token provenance checks for CALL and FUNCTION forms. Bare ELEMENTAL scalar, writable, explicit-shape, ALLOCATABLE/POINTER/TARGET/CLASS dummy policies are not broadened. Existing CHARACTER gathering, numeric row-only rank-two gathering and one-vector-axis rank-three gathering remain within their own contracts.

TRAILZ supports INTEGER kinds 4/8 scalar/rank 1–3 values, returning default INTEGER with elemental shape. Zero returns the operand width and negative values are processed at that width without negating the machine minimum. ISO_FORTRAN_ENV now exposes INT8=-1, INT16=-1 and INTEGER_KINDS=[4,8] as the interpreter's availability model, with scoped import/alias and indexed parameter handling. These values intentionally differ from a host compiler that implements additional integer kinds. They do not enable small-kind declarations, literals, conversions or arithmetic. See [TRAILZ and availability](TRAILZ-ISO-INTEGER-AVAILABILITY.md).

No resource cap, scatter rule or ordinary-function external-I/O policy changes. INQUIRE, F0.d and array-element substring drafts are excluded.

## Original utility bodies and whole-file boundaries

The untouched utility source still rejects its excessive array declaration at 9329:55. The separately authorized nmax=100000 working copy advances through numeric vector selection to 2992:1 INQUIRE. The clean run confirmed both check/run boundaries with empty stdout, including the working-copy run with `--max-steps 100000000`; GNU compiled and ran the complete working source under its recorded dialect. These checks do not establish complete FortFront library execution. Standalone original-body successes and retained full-function effect boundaries retain their exact provenance; GNU compilation/execution is reported separately.

## Validation and delivery

The clean maintained run passed all 11,389 source-contract outcomes across 195 suites, with 277 native test programs and 7 separately reported static/shared comparisons. It also passed 2,575 Python test methods and 10,566 separately counted integer-mask assertions.

The separate fresh reconstructed M_intrinsics survey recorded 74 ordinary GNU-agreeing complete examples out of 249 pinned sources; its remaining categories are reported separately.

All final counts and identities come from the reviewed retry02 evidence, not previews or earlier failed/interrupted runs. The nine-file metadata successor preserves source bodies and records exact historical expectation progress. Reconstructed survey checks are not the lost historical harness. See [verification](VERIFICATION.md) for strict categories, source/dynamic-evidence audits and retained failures.

The main `fortfront-interpreter-0.53.0.zip` and companion `fortfront-interpreter-0.53.0-verification.zip` share one project root and must be extracted into the same parent directory for complete current proof. The main source is compile-ready alone; the companion adds verification, not replacements. [Delivery](../DELIVERY.md) binds the actual pair and external checksums. Historical versioned evidence remains historical.
