# Changelog

## 0.49.0

- Fix mixed initialized/uninitialized derived declarations and add bounded scalar fixed-length default CHARACTER components with checked ownership, schema and record-storage limits.
- Admit checked runtime INTEGER stdout-unit names, function-generic REPEAT intrinsic fallback, bounded slash record output and default-INTEGER LEADZ results for INTEGER4/8 operands.
- Preserve exact user/utility/demo sources; the adapted utility still rejects at 2376:11 and the original retains its array-cap boundary.
- Record local producer patches 0104/0105. See [current scope](docs/RELEASE-0.49.md); final verification remains separately measured.

## 0.48.0

- Support descriptor-known runtime CHARACTER lengths in untyped constructors, including checked empty and fixed-length unallocated inquiry paths.
- Add bounded INTEGER IAND, IOR, IEOR, NOT, BIT_SIZE and BTEST with independent producer, adapter and runtime guards.
- Add INTEGER B/O/Z output editing and reject forged output-value kind metadata before commit.
- Add bounded SYSTEM_CLOCK/CPU_TIME scalar-output queries using actual host clocks, with deterministic typed-sample validation tests and separate environment-sensitive evidence.
- Preserve all original program fixtures and the exact one-byte utility adaptation; the merged working source now reaches the runtime-unit WRITE boundary at 1208:8.
- Record producer patch 0099; reserved 0098, 0100 and 0101 need no vendor change.

## 0.44.0

- Add bounded output implied-DO lists, whole scalar runtime formats, named WRITE controls and nonadvancing stdout record handling.
- Add ACOSD, ASIND, SIND, COSD and whole CHARACTER %LEN inquiries with independent producer/adapter/runtime validation.
- Add actionable CLI step-budget advice without changing the API diagnostic or source location.
- Retain the original utility source and include the explicitly authorized one-byte 100,000-element working-copy adaptation with separate provenance and outcomes.
- Preserve existing array, output, CHARACTER and work limits; record cumulative producer corrections 0081–0084.

## 0.43.0

- Correct token-class handling so punctuation-only CHARACTER literals remain data and quoted delimiters cannot satisfy grammar. Independent unchanged composition cases and malformed-source tests cover the correction.

- Add bounded CHARACTER defined plus, scalar allocatable CHARACTER and internal list-directed READ with independent source/IR validation.
- Add DIGITS, NEW_LINE and RRSPACING, plus colon edit descriptors for supported formats.
- Preserve original utility/demo source bytes and existing limits; record cumulative vendor corrections 0077, 0078 and 0080 (0079 unused).

## 0.42.0

- Raise the default named array cap to 1,000,000 and document an opt-in 10,000,000-element build, retaining independent work, CHARACTER-byte and output limits.
- Compact numeric/logical/CHARACTER values by making derived-record payloads optional, preserving deep-copy ownership and definition flags.
- Add mandatory specification-length ALLOCATABLE CHARACTER dummies with entry-frozen lengths and exact actual-length validation; execute original compress bodies unchanged.
- Refresh only generated resource-policy fixtures for the configured cap and retain original user/utility sources unchanged.

## 0.41.0

- Add bounded REAL(4/8) ASIN, one/two-argument ATAN and ATAN2, preserving finite domains, elemental kinds/shapes and independent source/IR validation.
- Accept named scalar CHARACTER PARAMETER formats in supported PRINT/WRITE forms without permitting arbitrary runtime formats or changing output limits. Execute unchanged original SIN and ASIN examples.
- Add typed empty INTEGER/REAL kind 4/8 and default LOGICAL constructors with explicit type identity; promote existing filter and empty-constructor drivers through metadata only.
- Preserve original sources, existing resource limits and the normal-mixture acceptance suite. Record cumulative vendor patches 0074 and 0076; 0075 is unused.

## 0.40.0

- Execute the exact supplied normal-mixture example and labeled ACOS-PI variant using bounded REAL(KIND), ACOS, no-argument RANDOM_SEED and multi-object allocation support. Preserve input bytes and distinguish stochastic checks from deterministic EM comparisons.
- Add DPROD, bounded finite TAND, spaced/compact DOUBLE PRECISION, initialized intrinsic main SAVE objects and literal unlimited-repeat/G0 formats.
- Retain existing caps, finite-value and source/IR checks; record cumulative vendor patches 0070–0073, strict GNU comparisons, mathematical probes and fresh-cache full regression.

## Unreleased: exponent-model inquiries

- Add bounded MINEXPONENT/MAXEXPONENT for REAL kinds 4/8, metadata-only whole scalar/array arguments, constant eligible-variable inquiries and default INTEGER scalar results.
- Retain the unchanged M_intrinsics demo_minexponent with GNU agreement. Record subobject, nonconstant-initializer and original demo_maxexponent boundaries without source adaptation.
- Add producer registrations/metadata in vendor patch 0069, independent IR mutations, empty/KIND checks and source oracle coverage.

## Unreleased: ASSOCIATED TARGET

- Add bounded two-argument ASSOCIATED with exact ordered storage identity, optional keywords, lifetime validation and descriptor-only inquiry behavior. Preserve empty-target and undefined-pointer distinctions.
- Add the unchanged M_intrinsics demo, independent GNU comparisons and public-IR mutation guards. Document three specification-only OPTIONAL omission cases separately from GNU execution agreement.
- Repair independent producer default LOGICAL kind metadata via vendor patch 0065.

## 0.27.0

- Add OPTIONAL INTEGER/REAL/LOGICAL rank-one/rank-two assumed-shape arrays and supported numeric allocatable arrays, preserving presence, kinds, bounds, definition flags and writable-alias checks. Extend INDEX BACK absence to supported LOGICAL arrays.
- Add OPTIONAL default CHARACTER scalar and rank-one/rank-two dummies, including bounded allocatable forms, omission, direct forwarding, PRESENT and definedness-safe entry/copyback. Retain independent declaration and descriptor validation.
- Add bounded scalar-base CHARACTER substring reads and assignment, omitted bounds, zero lengths, overlap-safe writes, specification inquiries and input expression actuals. Keep writable substring actuals and array/literal/function-result bases unsupported.
- Add elemental INDEX, LEN_TRIM, ADJUSTL and ADJUSTR with keywords, scalar/rank-one/rank-two arrays, constant supported KIND and checked absence/shape behavior. Admit documented LEN_TRIM-based length and bound expressions.
- Preserve exact original utility bodies in independent focused and combined drivers. These are not execution of the complete original utility module; the unchanged full source now first rejects rank-three arrays at 1829:62.
- Add replayable vendor patches 0043–0046, strict producer/adapter/runtime mutations, independent GNU comparisons, failure tests and cross-feature regressions. Windows and the standalone upstream FortFront test suite remain unverified.

## 0.26.0

- Add bounded rank-one/rank-two allocatable default CHARACTER arrays, fixed/assumed/deferred lengths, typed deferred ALLOCATE, descriptor-aware assignment and dummy/result copyback, preserving empty lengths and checked allocation limits.
- Add simultaneous FORALL statements and constructs with one or two independent INTEGER indices, optional frozen masks, array elements/sections, checked duplicate destinations, and staged statement commits. Keep nested FORALL, named constructs, WHERE bodies and more than two indices explicitly unsupported.
- Add elemental NINT, FLOOR, CEILING and LOG10 with REAL(4/8) inputs, scalar/rank-one/rank-two shape, constant INTEGER result KIND=4/8 for rounding, keywords and checked domains/overflow.
- Preserve unchanged original utilities bodies in focused and combined wrappers, including allocatable CHARACTER setters, FORALL array utilities, munge, floor_10 and ceiling_10. Preserve every original source byte; full-file execution remains unsupported, with the first diagnostic advancing to OPTIONAL CHARACTER at 597:54.
- Add independent producer/adapter/runtime checks, GNU comparisons and cross-feature tests. Retain replayable vendor patches 0040–0042 and earlier provenance. Windows execution and the standalone upstream FortFront test suite remain unverified.

## 0.25.0

- Infer each CHARACTER(*), PARAMETER entity's length from its constant initializer, preserving empty values, trailing blanks, scalar expansion and zero-sized/rank-one/rank-two arrays. Keep constant-expression, type, shape and length-limit checks.
- Add bounded elemental default-character CHAR/ACHAR for INTEGER(4/8), optional constant KIND=1, and ASCII codes 0:127; reject invalid constant/runtime values without wrapping.
- Add strict producer patch 0038 for CHAR/ACHAR metadata and nested-keyword declaration lookahead. Add independent GNU, producer, adapter-mutation and runtime-mutation tests.
- Preserve all original utilities bytes. The next complete-file boundary advances from line 499 to CHARACTER allocatable dummy words at 595:45. The full utility library remains unsupported.

- Add bounded default CHARACTER assumed-shape dummy arrays, explicit-shape array results and procedure-local/result length expressions, with entry-time descriptors and LEN inquiries. Keep independent shape/length/definition/alias checks and explicit allocation/substring/optional boundaries.
- Add REAL(4/8) scalar/rank-one/rank-two SIN, COS and TAN, with keywords, constants, empty arrays and independent malformed-metadata checks.
- Preserve concat_char_vec and five original trigonometric utility bodies in new wrappers, with exact source/body hashes and separate synthetic cross-feature tests.
- Add replayable producer patch 0039 for canonical CHARACTER procedure metadata. Fix the previously stale CLI version string and rerun the final clean source archive and pinned M_intrinsics survey. Windows and standalone upstream FortFront execution remain unverified.

## 0.24.0

- Add bounded rank-one/rank-two INTEGER(4/8) and REAL(4/8) allocatables: ALLOCATE/DEALLOCATE with optional STAT, ALLOCATED, local/module lifetimes, whole-array reallocation, allocatable results and explicit-INTENT allocatable dummy descriptors. Keep definition, bounds, alias and live-storage checks.
- Expand scalar literal-format PRINT/internal WRITE to supported arrays in Fortran element order. Flat PRINT formats revert to new records; internal WRITE stays single-record. Preserve failure-atomic rendering, output limits and explicit rejection of groups, slash edits, dynamic formats and general external I/O.
- Preserve module PARAMETER array descriptors inside nested calls while retaining shared mutable allocation descriptors; add nonunit-bound, rank-two, empty and corrupted-cache regressions.
- Add replayable FortFront patches 0036 (allocation child ownership) and 0037 (default-off strict semantic option for allocatable assignment); other strict checks remain active.
- Retain the full original utilities bytes, test alloc_sub_vec_int/real procedure text in a new driver, execute the complete unchanged M_intrinsics demo_dot_product, and combine allocation with formatted output in independent fixtures. The full utilities first rejection advances to inferred-length CHARACTER PARAMETER at 499:30.
- Run fresh-source native/regression/GNU verification and a full pinned M_intrinsics survey. Windows execution and the standalone upstream FortFront test suite remain unverified.

## 0.23.0

- Add shared per-execution mutable module scalars and explicit-shape arrays, constant initialization, persistent definition flags, imported writes, visibility, PURE/SIMPLE checks and conservative transitive module-actual alias guards.
- Add numeric rank-one/rank-two MINLOC/MAXLOC with DIM, MASK, KIND and BACK, plus the bounded DIMENSION declaration attribute needed by the unchanged original iminloc body.
- Support constant rank-one/rank-two RESHAPE declaration and PARAMETER initializers with independent shape validation; preserve the original demo_unpack initializer slice.
- Advance the untouched utilities boundary to ALLOCATABLE module data at line 495, column 10; allocation and broader full-file support remain separate work.

## 0.22.0

- Raise independently checked whole-source metadata capacity to 8,192 symbols, 1,024 procedures, 256 named generics and 1,024 accessibility/USE ONLY names. Enlarged tables and sparse call-graph analysis use heap storage rather than large stack allocations; active runtime depth remains 64.
- Allow bounded scalar COUNT reductions over supported input masks in automatic local/result bounds, preserving once-per-entry shape, undefined-value checks and shared frame/work limits.
- Add rank-one/rank-two PACK with scalar/conformable masks and optional VECTOR, and bounded RESHAPE with runtime SHAPE, PAD cycling, ORDER and keywords. Preserve types, kinds, fixed CHARACTER lengths, empty-array behavior and independent IR validation.
- Execute exact original true_pos_func, positive_int_vec, vector and matrix_from_vec bodies in focused and combined GNU differential tests. Preserve the original utilities source and all earlier Fortran fixtures and vendor attribution.
- The full original utilities source now passes the former metadata cap but still rejects mutable module data at line 493. Allocatable/CHARACTER procedure composition and broader language support remain separate work; Windows execution remains unverified.

## 0.21.0

- Bounded rank-one/rank-two procedure-local automatic arrays with dummy-dependent INTEGER specification expressions, once-per-entry bounds, fresh storage and checked frame limits.
- Non-ELEMENTAL numeric/logical array function results with constant/automatic shape, owned result storage, per-statement caching, full definition checks and bounded temporaries.
- REAL(4/8) SINH, COSH and TANH for scalar/rank-one/rank-two expressions, including X= keywords, constant evaluation and checked non-finite results.
- Retain original normalize, difference, growing-mean, bin-count and sech utility bodies with new differential, malformed-IR, boundary and cross-feature checks. Preserve all earlier source fixtures and replayable vendor patches 0032/0033.
- Windows-compatible source layout and portable verifier retained; Windows execution and the full original utilities module remain unverified/unsupported respectively.

## 0.20.0

- Defined unary/binary operators for supported intrinsic and derived operands, exact overload resolution, elemental arrays, visibility and USE ONLY.
- Scalar numeric/logical OPTIONAL dummies, PRESENT, absent forwarding, optional keyword slots, elemental/generic/bound calls and runtime absence checks.
- ELSE IF/ELSEIF, named counted DO, EXIT/CYCLE and exact INTEGER(8) loop control with checked terminal overflow.
- ALL, ANY, COUNT with DIM/KIND, MERGE and DBLE over supported scalars and rank-one/rank-two arrays.
- Same-file module dependencies with scope-aware USE association and complete chained PARAMETER declarators.
- New focused and combined GNU differential corpora, native malformed-IR checks and replayable vendor patches. Original utility bodies and constant declarations retain source maps.
- Windows-compatible source and portable verification scripts; Windows execution remains unverified. Full supplied utilities are still outside the supported subset.

# Release history

## 0.19.0

- Raise source capacity from 65,536 to 1,048,576 bytes and tokens from 20,000 to 262,144 through shared build-time constants in `src/fi_limits.f90`.
- Grow lexer token storage on demand, retain explicit allocation diagnostics and enforce identical source limits in the CLI and reusable APIs. Preserve independent language and resource boundaries.
- Add bounded SELECTED_REAL_KIND with optional P/R/RADIX and keyword association over the supported REAL32/REAL64 model, retaining independent producer/adapter/runtime checks.
- Preserve the supplied large utilities source and decompose it into smaller review units and executable focused cases. Report the remaining full-file and slice boundaries instead of claiming general Fortran 95 coverage.
- Add exact size/token boundaries, real-file assessment and GNU differential regressions. Retain previous source fixtures, vendor provenance and historical verification.

## 0.18.0

- Execute the requested CHARACTER-array, named generic `twice`, and original CLASS-based date examples unchanged.
- Add fixed-length default CHARACTER arrays, elements/sections, PARAMETER arrays, homogeneous and length-specified constructors (including typed empty forms), concatenation, scalar expansion and padded comparisons.
- Add bounded named module generic functions/subroutines with exact type/kind/rank and keyword selection, visibility and ELEMENTAL lifting. Retain independent source/AST selection checks.
- Add exact-type scalar CLASS dummies, default-PASS type-bound methods and captured defined formatted output through bare DT and list-directed PRINT. Preserve atomic parent records and explicit limits on polymorphism and external I/O.
- Add focused differential, malformed-IR/producer and cross-feature tests. Correct generic ELEMENTAL REAL64 result metadata without bypassing the adapter's result checks.
- Retain vendor patches 0021–0024, source provenance, MIT notices, earlier tests and historical reports.

## 0.17.0

- Raise the shared array-element cap to 131,072 through the single `max_array_elements` constant in `src/fi_ir.f90`; preserve independent output/source/CHARACTER/work limits and execute the exact 100,000-value random summary program.

- Fix REAL64 array-expression actual arguments such as `mean(x**2)`, sharing declaration-resolved type inference with strict argument checking while retaining mismatched kind/rank rejection. Include the exact reported RNG/mean program and GNU/producer/adapter regressions.
- Execute the priority scalar-derived month-date program and SELECT CASE example unchanged, with independent GNU comparisons and cross-feature cases.
- Add bounded scalar module TYPE definitions, constructors, components, whole-value copy, TYPE dummies/results and binary defined operators; retain explicit limits on CLASS, type-bound procedures, derived arrays and defined I/O.
- Add SELECT CASE for INTEGER/CHARACTER/LOGICAL, fixed CHARACTER values/results/dummies, TRIM and constant numeric/logical array parameters.
- Add checked INTEGER kinds 4/8, SELECTED_INT_KIND, INT(KIND=), MODULO, function-name results, normal STOP and bounded internal formatted WRITE with literal text and zero-padded integer edits.
- Preserve previous corpus/example source fixtures byte for byte, updating expectations for newly supported features and the larger array cap; parameterize one native over-limit boundary probe. Repair imported array references and full logical initialization in the pinned producer. Keep the FPM/vendor layout and attribution, with replayable producer fixes.

## 0.16.0

- Execute both unchanged requested mean programs: KIND(1.0d0), REAL64 constructor declaration initialization and CALL RANDOM_NUMBER on 1,000 REAL64 elements.
- Add non-evaluating KIND inquiries, bracket/legacy rank-one constructors and main-program scalar/array constant initialization, preserving all supported type/kind/shape checks.
- Add REAL scalar/element/rank-one/rank-two/section RANDOM_NUMBER with HARVEST keyword, deterministic per-execution state and whole-call staged updates under the shared work limit.
- Add independent GNU/oracle cases and native malformed-IR tests. Retain four old fixture sources and update their supported-feature expectations.
- Preserve existing frontend source provenance, licensing and all previous suites; describe the narrower constructor/RNG contract explicitly.

## 0.15.0

- Add ELEMENTAL subroutines with checked scalar/rank-one/rank-two OUT/INOUT association, frozen whole-reference aliases and definition-state-preserving copy-back.
- Add explicitly IMPURE ELEMENTAL functions/subroutines with array element order, function result caching per statement execution, and checked recursive PRINT rejection.
- Preserve exact type/kind matching, pure/simple call closure, empty-call behavior, arithmetic checks and shared resource budgets.
- Add 128 independent cases, native adapter/runtime/producer regressions, explicit oracle limitations, and replayable producer patch 0012 for elemental CALL argument checking.
- Reclassify the two former unsupported elemental-subroutine/impure-function fixtures as supported; keep earlier feature regressions and historical verification evidence.

## 0.14.0

- Add pure ELEMENTAL functions over scalar and conformable rank-one/rank-two actuals, retaining scalar dummy/result declarations and exact types and REAL kinds.
- Compose scalar expansion, keyword arguments, section strides, nested functions, zero extents, inquiries, reductions and overlap-safe array assignment.
- Retain implicit ELEMENTAL purity independently of explicit PURE/SIMPLE prefixes; reject ELEMENTAL subroutines, IMPURE procedures and non-scalar elemental dummies.
- Execute every array element through the existing checked scalar call-frame machinery, preserving definition flags, arithmetic diagnostics and the shared work budget.
- Add native adapter/runtime/producer tests, independent compiler-oracle cases and a targeted, replayable producer correction for ELEMENTAL argument association and result type/rank metadata.
- Preserve all earlier source cases, examples, licensing, FPM layout and historical verification reports.

## 0.13.0

- Add distinct Fortran 2023 SIMPLE designation and strengthen independent PURE/SIMPLE checking for supported module/internal functions and subroutines.
- Enforce PURE-to-PURE/SIMPLE and SIMPLE-to-SIMPLE call closure in expressions and CALL statements, including uncalled/unreachable bodies.
- Accept type and designation prefixes in either order, plus redundant PURE SIMPLE, while rejecting duplicates and unsupported attributes conservatively.
- Preserve explicit PURE, effective purity and SIMPLE in IR; retain SIMPLE in FortFront ASTs and fix internal typed-header prefix loss.
- Add native producer/adapter regressions and 121 independent CLI cases, with direct PURE compiler evidence separated from weakened SIMPLE arithmetic references.
- Retain all previous tests, examples, licenses and the unchanged execution runtime; document the narrower supported subset and lack of a native SIMPLE compiler oracle.

## 0.11.0

- Add SUM, PRODUCT, MINVAL and MAXVAL on rank-one/rank-two INTEGER/REAL arrays with positional runtime DIM and scalar/conformable LOGICAL MASK.
- Add numeric and LOGICAL DOT_PRODUCT and all three valid rank-one/rank-two MATMUL combinations, with numeric type/kind promotion and empty-inner identities.
- Compose intrinsic results with sections, expressions, inquiries, assignment and assumed-shape IN arguments, preserving overlap-safe writes and existing SUM procedure overrides.
- Independently validate intrinsic argument/result metadata against FortFront; bound result shapes and charge all reduction/product iterations to the shared budget, with checked intermediate arithmetic.
- Add independent GNU differential, safe-failure, malformed-IR and frontend mutation coverage; retain prior tests, frontend source, FPM configuration and licenses. Keyword arguments, complex and higher-rank arrays remain explicitly unsupported.

## 0.10.0

- Add rank-two triplet sections and rank-reducing scalar/triplet combinations in either dimension.
- Support runtime bounds and signed strides, omitted operands, empty sections, elemental expressions, PRINT and dimension inquiries.
- Share frozen column-major section mappings across overlap-safe assignment and assumed-shape IN/OUT/INOUT argument association, including nested forwarding and precise alias checks.
- Independently check every scalar/triplet operand, dimension and cached result rank against FortFront; add native mutation and GNU differential regressions.
- Preserve the pinned frontend, FPM build, previous fixtures and notices. Rank three, vector subscripts, dynamic declarations and other unlisted features remain explicitly unsupported.

## 0.9.0

- Add explicit-shape rank-two arrays with per-dimension constant bounds, two scalar subscripts, checked column-major storage and zero extents.
- Add shape-conforming whole-array assignment, scalar expansion, elemental operations, PRINT and per-dimension SIZE/LBOUND/UBOUND inquiries.
- Add rank-two assumed-shape IN/OUT/INOUT dummy arguments with rebased bounds, preserved definition state, nested forwarding and conservative alias checks.
- Permit fresh explicit-shape rank-one/rank-two procedure locals while retaining scalar function results.
- Independently cross-check both dimensions and element indices against FortFront, add matrix multiplication example and differential/mutation coverage; preserve rank-one sections and previous semantics.
- Reject rank-two sections, rank-three and higher arrays and unlisted array features explicitly.

## 0.8.0

- Add scalar INTENT(OUT)/INTENT(INOUT) subroutine arguments, including caller array elements, with preserved definition state and nested forwarding.
- Add rank-one assumed-shape IN array dummies to functions/subroutines and writable OUT/INOUT array dummies to subroutines, including strided/empty actuals and IN expression temporaries.
- Add scalar SIZE/LBOUND/UBOUND inquiries, rebased dummy bounds, strict type/kind/rank checking and conservative writable-alias rejection.
- Extend independent GNU differential, unsupported-source, runtime-policy and adapter tests; retain all previous source fixtures and licenses.


## 0.7.0 — Numerical procedures and Black-Scholes

- Execute both exact user programs unchanged: Black-Scholes benchmark/parity tests and the module subroutine example.
- Add REAL64 and named/numeric kind suffixes, ISO_FORTRAN_ENV real kinds, module PARAMETER data, PUBLIC/PRIVATE and USE ONLY.
- Add typed/PURE function headers, scalar module/internal subroutines, CALL, CHARACTER(LEN=*) INTENT(IN) arguments, RETURN and immutable host constants.
- Add EXP, LOG, SQRT, ERFC, between-token continuation, single-line IF, ERROR STOP and restricted literal formatted PRINT.
- Preserve REAL32 rounding and enforce REAL kind agreement at calls; retain bounds, initialization, recursion, frame and shared-budget checks.
- Extend strict FortFront cross-checks and document vendor patches 0004–0006 with replay verification.
- Add an independent numerical/procedure corpus, a 272-value GNU arithmetic matrix, and native runtime/frontend/producer regressions.


## 0.6.0

- Support same-file modules and scalar module functions imported by plain USE.
- Require explicit scalar RESULT and positional scalar INTENT(IN) arguments with exact type/rank matching.
- Resolve sibling and forward calls, preserve scoped local names, and isolate every call frame.
- Share bounded execution across nested calls and reject recursive cycles and unsupported side effects.
- Cross-check module/function/USE declarations, argument lists, scope bindings and calls against the original FortFront tree.
- Add the exact requested example, independent GNU differential cases and direct adapter/runtime disagreement tests.


## 0.5.0 (2026-11-14)

- Add rank-one subscript triplets with runtime scalar INTEGER endpoints/strides,
  omitted operands, selected-index bounds checks and zero-sized sections.
- Support sections in elemental expressions, PRINT and overlap-safe assignments;
  evaluate section descriptors once per statement and check dynamic conformance.
- Cross-check FortFront slice/range trees and add native mutation/runtime tests
  plus an independent compiler-comparison corpus. Preserve existing fixtures,
  migrating only four newly supported section expectations.
- Preserve the pinned FortFront sources and notices unchanged.

## 0.4.0

- Whole-array assignment for existing rank-one explicit-shape INTEGER, REAL and
  LOGICAL arrays, including scalar expansion and numeric conversions.
- Elementwise unary/binary expressions and ABS, INT, REAL, MOD, MIN and MAX.
- Whole-array PRINT and empty-array behavior.
- Extent-based conformance independent of lower bounds, with scalar-only
  subscripts, IF conditions and DO control expressions.
- Complete right-hand temporary evaluation before assignment commit; complete
  PRINT evaluation before output. Existing overflow, initialization and work
  limits remain checked for every evaluated element.
- Independent frontend shape derivation and mutation regressions.
- 147 new differential/policy cases and 34 new direct runtime contracts.
- Eight old rejection expectations migrated without changing their source.

## 0.3.0

Implicit main programs and scalar PARAMETER constants; 32/55 requested examples,
power regressions and portable verification scripts. See docs/VERIFICATION-0.3.0.md.

## 0.2.0

Rank-one explicit-shape arrays and element access. See docs/VERIFICATION-0.2.0.md.

## 0.1.0

Initial checked scalar interpreter and pinned FortFront adapter.

## Numeric model inquiry extension

- Added scalar EPSILON/TINY/HUGE/RADIX inquiries with bounded INTEGER(4/8) and REAL(4/8) models, exact result kinds, positional/keyword association, and metadata-only non-evaluation consistent with KIND.
- Added independent producer metadata, adapter and direct-runtime guards, GNU differential coverage and unchanged M_intrinsics demo checks. See `docs/NUMERIC-MODEL-INQUIRIES.md`.


## Unreleased: SPACING and NEAREST

- Add precision-correct REAL4/8 SPACING/NEAREST with independent metadata guards, finite-domain checks, and unchanged M_intrinsics demo_spacing coverage.

## Next milestone: initialized main-program SAVE

- Accept bounded explicit SAVE attributes on constant-initialized main intrinsic scalars and rank-one/two/three arrays, without changing procedure storage.
- Execute the unchanged full demo_minloc, preserve demo_maxloc as a constructor-implied-DO boundary, and verify fresh state across same-IR root executions.
- Promote the existing main_explicit_save manifest expectation without editing its Fortran source.

## Next milestone: multi-object allocation

- Add bounded 2–64-object ALLOCATE/DEALLOCATE groups with full metadata/effect preflight, selected left-to-right prefix semantics and once-per-statement STAT.
- Preserve scalar INTEGER bounds, all supported allocatable kinds/ranks, CHARACTER descriptor failure state and resource caps.
- Fix contextual allocation option names and lexical DEALLOCATE binding in DO bodies; preserve old single-object behavior.

## Scalar allocatable CHARACTER extension

Default-kind scalar CHARACTER now supports checked allocation status, whole-variable length reallocation, procedure argument transfer and fresh local lifetimes. The unchanged M_intrinsics demo_adjustl executes against GNU. See [the supported subset and evidence](docs/SCALAR-ALLOCATABLE-CHARACTER.md).
