# Bounded rank-three allocatables

The original rank-three milestone extends the existing allocatable-array path through rank three. It does not add rank four, LOGICAL allocatables, general rank-three reductions, or unrestricted Fortran allocation syntax.

## Supported and tested behavior

- INTEGER, REAL, REAL(8), fixed-length CHARACTER, and deferred-length CHARACTER allocations use all three lower/upper bounds. Third-axis indexing and bounds failures are checked.
- ALLOCATED, ALLOCATE, and DEALLOCATE work with module and local descriptors. Repeated native execution starts module allocations fresh.
- Recoverable STAT failures leave the descriptor unchanged: double allocation preserves bounds/data; element capacity and CHARACTER storage capacity leave a previously unallocated destination unallocated. Subsequent successful allocation proves there was no hidden capacity/descriptor commit.
- Same-shape assignment preserves destination bounds. A changed shape adopts whole-array source bounds, while expressions and function results use expression bounds. CHARACTER length changes are tested separately: assigning a scalar character to an allocated array broadcasts/truncates/pads without reallocating its length.
- Zero-size shapes retain their other extents. Numeric and CHARACTER allocatable function results, including a zero-size numeric result, survive return and assignment.
- Allocatable INTENT(IN), INTENT(OUT), INTENT(INOUT), nested forwarding, and OPTIONAL dummies retain descriptor semantics. A present unallocated allocatable differs from an omitted OPTIONAL argument. INTENT(OUT) deallocates on entry. Deferred-length CHARACTER descriptors carry length and bounds back to callers.
- Invalid INTENT(IN) allocation and fixed-array actual arguments are rejected, with GNU independently rejecting those invalid programs. At that milestone, rank four and LOGICAL allocatables were explicit interpreter exclusions.

Allocation still accepts one target per statement and optional STAT. SOURCE/MOLD/ERRMSG and multi-target allocation were not added. Scalar allocatables are outside this array milestone. Existing storage caps remain enforced; supporting another rank does not raise those limits.

## Independent evidence

`tests/rank_three_allocatables/manifest.json` defines 25 fixtures with fixed expected values. `results.json` records separate candidate check/run and GNU oracle results: 25 candidate cases and 20 GNU comparisons, with 5 explicit interpreter-policy skips. Native `test/test_rank_three_allocatables.f90` checks two valid baselines, repeated module reset, and 19 forged states at both adapter and runtime boundaries (38 rejection checks). Forged states include rank four, hidden third-axis bounds/expression metadata, missing or surplus allocation operands, out-of-range third bound expression IDs, nonallocatable/assumed-shape/automatic descriptor confusion, malformed deallocation operands, and invalid deferred CHARACTER length metadata.

The runner's 12 self-tests exercise numeric, formatting, rejection, exit-boundary assessment, and output-leak comparison behavior. GNU runs use a fresh directory per case to avoid stale module files. Expected results are never populated from interpreter output. Rank-three SUM is not supported by the baseline; the fixtures deliberately use rank-two-plane checksums instead.

## Original utility boundary and next work

The unchanged `xutilities.f90` SHA-256 is `c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`. Its `combine_mat_tensor_real` begins at line 1981 and declares allocatable `ytens(:,:,:)` at line 1987. This milestone removes that rank-three allocatable declaration/allocation limitation. The synthetic augmentation fixture covers the corresponding allocation/section shapes on all three axes, before and after, without claiming the original routine has been executed.

In the integrated 0.29 release, split INTENT(IN OUT) and SHAPE are also supported. The unchanged full source instead stops at the LOGICAL ALLOCATABLE declaration at 2581:35. The synthetic augmentation fixture does not establish support for the original combine_mat_tensor_real routine or its full exclude/default/assert dependency graph. This milestone is not full xutilities support.

## Subsequent LOGICAL extension

The separate [LOGICAL-ALLOCATABLES.md](LOGICAL-ALLOCATABLES.md) milestone now admits
default LOGICAL allocatable arrays using these rank-one/two/three descriptors.
Its old `reject_logical_allocatable` fixture is retained unchanged and promoted
to a successful GNU comparison. The current rank-three allocatable manifest
therefore has 21 GNU comparisons and 4 interpreter-policy skips. The 25-case,
20-comparison evidence above records this milestone before that extension.
With LEN(element) and optional declaration separators integrated in 0.30, that release reached TARGET in get_data at 6325:38. Version 0.31 accepted TARGET and rejected POINTER at 6326:16. Version 0.32 adds bounded POINTER views and explicit dummies and now rejects the user-defined choose(n,k) bound at 7967:40. The 2581:35 diagnostic above records the 0.29 release boundary.

## Current 0.35 full-source boundary

The unchanged original now reaches read_vec_data_unit at 9329:55, where the
fixed local xbig(nmax), nmax=10**8, exceeds the configured 1,000,000-element cap.
Check/run both reject before output. No limit is increased and no original
input is reduced to bypass the boundary. External READ/CLOSE remain unsupported.
Earlier line numbers describe feature checkpoints, not whole-library success.
See [INTERNAL-PROCEDURES.md](INTERNAL-PROCEDURES.md) and [VERIFICATION.md](VERIFICATION.md).
