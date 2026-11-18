# Third-party notices

## FortFront

- Project: https://github.com/lazy-fortran/fortfront
- Pinned revision: `9a5896a1fce32c394fd02dd1da1bd261ea7a646f`
- Original license: MIT, copyright (c) 2025 Christopher Albert.
- Original notice and full license: `vendor/fortfront/LICENSE`.
- Included files: the original `src/` library tree, with two documented metadata fixes, a semantic-scope case-normalization fix, and targeted array-reference inference, procedure semicolon-boundary, named-kind semantics, complete procedure IF parsing, exponent-only real literal, and ERFC intrinsic registration, and expression keyword-wrapper, conversion-intrinsic type/rank, PURE/SIMPLE prefix-retention, and ELEMENTAL call type/rank metadata and subroutine strict-call validation fixes, nested legacy constructor parsing, and KIND selector/type-inquiry metadata corrections, nested SELECT body parsing, derived constructor/type/interface visibility, and physical source-location metadata corrections, scope-aware array-expression actual-argument type resolution, USE-associated array binding recognition, complete logical declaration initialization, empty typed legacy constructors, scoped named generic interfaces/results, bounded CLASS/type-bound declaration metadata, SELECTED_REAL_KIND registration and keyword-slot metadata, complete ELSE IF bodies, defined-operator precedence/results, logical selection/conversion intrinsic metadata, chained module PARAMETER declarations, dynamic CHARACTER allocatable descriptor matching, complete bounded FORALL metadata, and rounding/LOG10 intrinsic metadata. The minimal vendored `fpm.toml` disables upstream executables, examples, and tests; it does not remove library modules.
- Local changes: `vendor/patches/0001-resolved-type-mode-and-character-kind.patch`, `vendor/patches/0002-case-insensitive-semantic-scope.patch`, `vendor/patches/0003-module-function-arguments-and-semicolons.patch`,
  `vendor/patches/0004-scope-aware-real-kinds.patch`,
  `vendor/patches/0005-procedure-complete-if-grammar.patch`,
  `vendor/patches/0006-exponent-literals-and-erfc.patch`,
  `vendor/patches/0007-array-dummy-argument-types.patch`,
  `vendor/patches/0008-expression-keyword-arguments.patch`,
  `vendor/patches/0009-conversion-result-types.patch`,
  `vendor/patches/0010-pure-simple-prefixes.patch`,
  `vendor/patches/0011-elemental-call-types.patch`,
  `vendor/patches/0012-elemental-subroutine-calls.patch`,
  `vendor/patches/0013-nested-legacy-constructors.patch`,
  `vendor/patches/0014-kind-inquiry-selectors.patch`,
  `vendor/patches/0015-nested-select-bodies.patch`,
  `vendor/patches/0016-derived-constructors-and-visibility.patch`,
  `vendor/patches/0017-stop-physical-source-location.patch`,
  `vendor/patches/0018-array-expression-actual-types.patch`,
  `vendor/patches/0019-imported-parameter-array-bindings.patch`,
  `vendor/patches/0020-complete-logical-initializers.patch`,
  `vendor/patches/0021-empty-typed-legacy-constructor.patch`,
  `vendor/patches/0022-named-generic-explicit-interfaces.patch`,
  `vendor/patches/0023-class-type-bound-defined-output.patch`,
  `vendor/patches/0024-named-generic-result-metadata.patch`,
  `vendor/patches/0025-selected-real-kind.patch`,
  `vendor/patches/0026-complete-elseif-bodies.patch`,
  `vendor/patches/0027-defined-operator-precedence-and-results.patch`,
  `vendor/patches/0029-logical-selection-conversion-intrinsics.patch`,
  `vendor/patches/0030-module-parameter-declarators.patch`,
  `vendor/patches/0032-real-hyperbolic-intrinsics.patch`,
  `vendor/patches/0033-standard-function-recursion-metadata.patch`,
  `vendor/patches/0034-module-declaration-accessibility.patch`,
  `vendor/patches/0035-location-intrinsics.patch`,
  `vendor/patches/0036-allocation-parent-links.patch`,
  `vendor/patches/0037-allocatable-reallocation-option.patch`,
  `vendor/patches/0038-character-parameter-initializers.patch`,
  `vendor/patches/0039-character-procedure-metadata.patch`,
  `vendor/patches/0040-allocatable-character-descriptors.patch`,
  `vendor/patches/0041-forall-construct-metadata.patch`,
  `vendor/patches/0042-rounding-intrinsics.patch`,
  `vendor/patches/0043-grouped-character-length.patch`,
  `vendor/patches/0044-character-substring-metadata.patch`,
  `vendor/patches/0045-character-intrinsics.patch`,
  `vendor/patches/0046-declared-array-intrinsic-shadowing.patch`,
  `vendor/patches/0047-where-construct-metadata.patch`, `vendor/patches/0051-findloc-metadata.patch`, and `docs/FRONTEND.md`.
  Patch-specific explanations and attribution accompany patches 0004, 0006, 0007, 0008, 0009, 0010, 0011, 0012, 0013, 0014, 0015, 0016, 0017, 0018, 0019, 0020, 0021, 0022, 0023, 0024, 0025, 0026, 0027, 0029, 0030, 0032, and 0033 in `vendor/patches/`.

The interpreter, its tests, and documentation are separate prototype work. Neither upstream authorship nor endorsement of this interpreter is implied. Build tools and compilers are not redistributed in this archive.

The SCAN/VERIFY registry and source-derived type/rank additions are documented in
`vendor/patches/0048-scan-verify-intrinsics.md` and retained in its matching patch.

The INTENT spelling and continued-comment declaration fixes are documented in
`vendor/patches/0049-intent-spelling-continuations.md` and its matching patch.

The SHAPE inquiry result type/rank/kind metadata addition is documented in
`vendor/patches/0050-shape-intrinsic-metadata.md` and retained in its matching patch.

## Supplied utility source

`tests/utilities_slices/source/xutilities.f90` is the user-supplied source, retained
byte for byte as input evidence. Its source fragments and extracted procedure
bodies retain their original provenance; no upstream authorship or new license
for that supplied code is asserted. The new harnesses and interpreter changes
are separate prototype work.

## M_intrinsics declaration fixture

`tests/reshape/demo_unpack_initializers.f90` retains the declaration block from
`urbanjost/M_intrinsics`, commit `fc14233036d910e3678d350efc24609e11475067`,
`example/demo_unpack.f90`. The new wrapper/PRINT driver only tests initializers.
The upstream MIT notice is reproduced in `tests/reshape/LICENSE-M_intrinsics`.

## M_intrinsics formatted-array example

`tests/formatted_arrays/cases/demo_dot_product.f90` is an unchanged copy from
[urbanjost/M_intrinsics](https://github.com/urbanjost/M_intrinsics), commit
`fc14233036d910e3678d350efc24609e11475067`,
`example/demo_dot_product.f90`. Its upstream license is preserved at
`tests/formatted_arrays/UPSTREAM-LICENSE`.

The REPEAT registry, scalar CHARACTER metadata and explicit procedure-binding
classification corrections are documented in
`vendor/patches/0053-repeat-intrinsic-metadata.md` and its matching patch.

The literal-substring structure and recursive control-keyword dispatcher correction
are documented in `vendor/patches/0052-literal-substring-structure.md`. The bare DO
semicolon correction is documented in `vendor/patches/0054-bare-do-semicolon.md`.
Both retain their matching local MIT-licensed patch files.

The strict CHARACTER dummy/actual length metadata correction is documented in
`vendor/patches/0055-character-argument-length-metadata.md` and its matching patch.
The bounded POINTER runtime adds no vendored source changes.

- Local vendor patch 0056 admits contextual PROCEDURE entity/dummy names while
  retaining keyword-clause parsing and strict semantic validation (MIT).

## M_intrinsics elementary numeric examples

`tests/elementary_math/cases/demo_dim.f90`, `demo_sign.f90` and
`demo_log_gamma.f90` retain complete unchanged upstream files from
`urbanjost/M_intrinsics`, commit `fc14233036d910e3678d350efc24609e11475067`.
Their MIT notice is retained at `tests/elementary_math/UPSTREAM-LICENSE`.
The local FortFront corrections are documented in
`vendor/patches/0057-elementary-math-metadata.md` and its matching patch.

## M_intrinsics PARITY example

`tests/parity_intrinsic/demo_parity.f90` is unchanged from
[urbanjost/M_intrinsics](https://github.com/urbanjost/M_intrinsics), commit
`fc14233036d910e3678d350efc24609e11475067`, `example/demo_parity.f90`.
The upstream MIT notice is preserved in `tests/parity_intrinsic/UPSTREAM-LICENSE`.
The new harness and interpreter changes are separate prototype work.

## M_intrinsics numeric-model demonstrations

The unchanged `tests/numeric_model_inquiries/original/demo_floor.f90`,
`demo_radix.f90` and `demo_tiny.f90` are test inputs from
https://github.com/urbanjost/M_intrinsics at commit
`fc14233036d910e3678d350efc24609e11475067`. Their source bytes and hashes are
recorded in `tests/numeric_model_inquiries/original-provenance.json`.
The upstream MIT license, including its copyright notice, is preserved unchanged
at `tests/numeric_model_inquiries/original/LICENSE`. These files are not interpreter
implementation code. No modifications were made to the demonstrations.

Local vendor patch0058 documents PARITY and numeric-model inquiry metadata after0057; see vendor/patches/0058-parity-numeric-model-metadata.md and its replay patch.

- Local vendor patch 0059 corrects vector-row result metadata and continued inline-IF
  physical action locations (MIT); see its matching patch and ledger entry.


The unchanged `tests/spacing_nearest/demo_spacing.f90` is from urbanjost/M_intrinsics commit fc14233036d910e3678d350efc24609e11475067. Its upstream license is preserved in `tests/spacing_nearest/UPSTREAM_LICENSE`; exact source provenance is in `upstream.json`.

- Local vendor patch0062 adds the ISNAN GNU-extension registry entry and logical
  elemental metadata (MIT), with its matching documented source patch.

## M_intrinsics model decomposition and ASCII-code examples

`tests/model_decomposition/cases/demo_fraction.f90`, `demo_set_exponent.f90`,
`demo_iachar.f90` and the explicitly blocked complete `demo_exponent.f90` retain
unchanged files from `urbanjost/M_intrinsics`, commit
`fc14233036d910e3678d350efc24609e11475067`. Their MIT notice is preserved at
`tests/model_decomposition/UPSTREAM-LICENSE`. The local producer changes are
recorded in `vendor/patches/0060-model-decomposition-metadata.md` and its patch.

## M_intrinsics ISO environment examples

`tests/iso_env_aliases/cases/demo_cosh.f90`, `demo_tan.f90`, `demo_tanh.f90`
and `demo_epsilon.f90` retain complete unchanged files from
`urbanjost/M_intrinsics`, commit `fc14233036d910e3678d350efc24609e11475067`.
Their MIT notice is preserved at `tests/iso_env_aliases/UPSTREAM-LICENSE`.
Local producer patch 0063 handles retained comment trivia in continued USE lists;
see `vendor/patches/0063-use-rename-continuations.md` and its matching patch.

- Local vendor patch 0064 adds ERFC_SCALED registry and elemental metadata (MIT).
  The unchanged M_intrinsics demo_erfc_scaled example and upstream MIT license
  are preserved under tests/erfc_scaled with commit/hash provenance.

## M_intrinsics CSHIFT example

`tests/cshift/demo_cshift.f90` is byte-identical to the complete example from
`urbanjost/M_intrinsics`, commit `fc14233036d910e3678d350efc24609e11475067`.
Its MIT license and copyright notice are preserved unchanged in
`tests/cshift/UPSTREAM_LICENSE`; exact source provenance is in the test manifest.
Local MIT-licensed producer patch0066 registers CSHIFT and preserves ARRAY
metadata. Its matching patch and explanation are under `vendor/patches/`.

## M_intrinsics ASSOCIATED example

The unchanged `tests/associated_target/demo_associated.f90` is from urbanjost/M_intrinsics,
commit `fc14233036d910e3678d350efc24609e11475067`. The retained upstream license is
`tests/associated_target/UPSTREAM_LICENSE`; source and license hashes are recorded
in `tests/associated_target/upstream.json`. No upstream source adaptation is made.

## M_intrinsics real rounding and inverse hyperbolic examples

The complete unchanged `tests/rounding_inverse_hyperbolic/cases/demo_aint.f90`,
`demo_anint.f90`, `demo_asinh.f90` and `demo_acosh.f90` are from
urbanjost/M_intrinsics, commit `fc14233036d910e3678d350efc24609e11475067`.
Their MIT notice is preserved in `tests/rounding_inverse_hyperbolic/UPSTREAM-LICENSE`
and exact hashes are recorded in `upstream.json`. Local MIT-licensed producer
changes are documented by vendor patch 0067 and its matching ledger entry.

`tests/erf_bessel/demo_*.f90` contains seven complete unchanged examples from
urbanjost/M_intrinsics commit fc14233036d910e3678d350efc24609e11475067.
The MIT license is preserved as `tests/erf_bessel/M_INTRINSICS_LICENSE`; individual
source identities and the singular Y0(0) boundary are recorded in that suite's
provenance and README. Numerical reference values are independently generated.

## M_intrinsics exponent-model examples

The unchanged `tests/exponent_inquiries/demo_minexponent.f90` and
`demo_maxexponent.f90` come from urbanjost/M_intrinsics commit
`fc14233036d910e3678d350efc24609e11475067`. Their original license is retained
as `tests/exponent_inquiries/UPSTREAM_LICENSE`; all three hashes are in
`tests/exponent_inquiries/upstream.json`.

## Cumulative 0.39 producer additions

All local producer corrections through0069 remain available with paired patch
and explanatory files under `vendor/patches/`. This release adds0067 real
rounding/inverse-hyperbolic metadata,0068 ERF/Bessel metadata and0069 exponent-model
inquiry metadata. The ordered replay preserves the pinned upstream license and
all previous corrections; its final104-entry registry is checked independently.

## M_intrinsics DPROD and TAND examples

The complete unchanged tests/dprod_tand/cases/demo_dprod.f90 and demo_tand.f90
are from urbanjost/M_intrinsics commit fc14233036d910e3678d350efc24609e11475067.
Exact hashes are in tests/dprod_tand/upstream.json and the original MIT notice is
preserved at tests/dprod_tand/UPSTREAM-LICENSE. Local MIT-licensed producer
metadata and DOUBLE PRECISION spelling changes are documented by vendor patch0070.

### Main-program SAVE original examples

`tests/main_save/demo_minloc.f90` and `demo_maxloc.f90` are complete, unchanged
M_intrinsics examples by urbanjost, commit `fc14233036d910e3678d350efc24609e11475067`,
from https://github.com/urbanjost/M_intrinsics. The MIT license is retained as
`tests/main_save/UPSTREAM_LICENSE`; exact file hashes are in `upstream.json`.

## M_intrinsics ERFC and LOG10 examples

The complete unchanged `tests/unlimited_formats/demo_erfc.f90` and
`demo_log10.f90` come from urbanjost/M_intrinsics commit
`fc14233036d910e3678d350efc24609e11475067`. Their MIT notice is retained as
`tests/unlimited_formats/M_INTRINSICS_LICENSE`; source and license hashes are
recorded in `provenance.json`. No upstream source adaptation is made.

## Version 0.40 producer corrections

Cumulative vendor patches 0070–0073 document DPROD/TAND and DOUBLE PRECISION spelling, REAL result-kind metadata, existing ACOS elemental metadata, and contextual ALLOCATE/DEALLOCATE option lookahead. ACOS was already registered upstream; 0072 does not add a duplicate. The cumulative registry has 106 unique entries. The MIT-licensed pinned frontend and all previous patches are retained.

The user-supplied xmix_dt program is retained as test input with exact source hashes, not imported as interpreter implementation or re-licensed. Its explicitly labeled ACOS variant changes only the two PI declaration lines; synthetic drivers preserve the module and replace only the test main program.

## M_intrinsics inverse trigonometric examples

The complete unchanged `tests/inverse_trigonometric/cases/demo_sin.f90` and
`demo_asin.f90` come from urbanjost/M_intrinsics commit
`fc14233036d910e3678d350efc24609e11475067`. Their original MIT notice is retained
as `tests/inverse_trigonometric/UPSTREAM-LICENSE`, with exact source and license
hashes in `upstream.json`. The default feature-only suite records demo_asin's
separate named-format dependency; a merged feature profile requires execution.
The local MIT-licensed producer correction is documented by vendor patch 0074.

## M_intrinsics named-format originals

The five complete unchanged examples under `tests/named_formats/demo_*.f90` come
from urbanjost/M_intrinsics commit fc14233036d910e3678d350efc24609e11475067.
Their MIT license is retained as `tests/named_formats/M_INTRINSICS_LICENSE`;
`provenance.json` records exact source identities and the distinction between
combined ASIN execution and four later original-program boundaries. No source
adaptations or replacement helpers are used.

## Defined CHARACTER plus producer correction

Local MIT-licensed patch 0077 preserves standard-source defined CHARACTER `+`
and source-OPTIONAL omission in named-generic result metadata. The registry is
unchanged. The exact original `char_plus_char`, `char_plus_int` and `str_int`
bodies in tests/character_plus are user-supplied utility test input, with raw-byte
provenance, not newly licensed interpreter implementation. Module/interface/driver
scaffolding is explicit and no helper substitution or full-library claim is made.

## Internal READ metadata correction

The local MIT-licensed producer correction is documented in vendor patch 0080.
It sets the generic READ factory's existing formatted flag; no intrinsic registry
entry is added. Exact user-supplied read_int_vec_alloc/read_real_vec_alloc bodies
are retained as test evidence, with source/CRLF hashes in
`tests/internal_read/provenance.json`, without relicensing that source.

## Output implied-DO producer correction and original examples

Local MIT-licensed vendor patch 0081 links existing output implied-DO objects and
controls to their parent node for independent declaration/type lookup. It adds no
intrinsic registry entry. Exact user-supplied join-family bodies remain test
evidence without relicensing; upstream M_intrinsics demo_trim retains its source
and pinned provenance in tests/output_implied_do.

## Degree intrinsic examples and metadata

The unchanged demo_acosd, demo_asind, demo_sind and demo_cosd files in tests/degree_trig come from MIT-licensed urbanjost/M_intrinsics commit fc14233036d910e3678d350efc24609e11475067. Exact hashes and the upstream license are retained there. Local producer patch0083 adds four degree names and elemental same-kind metadata; it does not import third-party numerical implementation.

## Process-query metadata and utility evidence

Local MIT-licensed vendor patch0085 registers GETCWD as a subroutine and adds it
to the existing impure-subroutine classifier. The exact user-supplied exe_name
body is retained only as test evidence, without relicensing; source and CRLF
hashes are in tests/process_queries/provenance.json. No third-party process-query
implementation is imported. Native GNU intrinsics supply the bounded inquiries.

## Lexical comparison examples and metadata

The unchanged demo_lge, demo_lgt, demo_lle and demo_llt programs in tests/lexical_comparisons come from MIT-licensed urbanjost/M_intrinsics commit fc14233036d910e3678d350efc24609e11475067. Source hashes and the original license are retained there. Local vendor patch 0086 adds four registry identities and elemental default-LOGICAL result metadata; the independent ASCII comparator is local implementation.

## CHARACTER MIN/MAX original examples

The unchanged demo_max and demo_min sources in tests/character_minmax are from MIT-licensed urbanjost/M_intrinsics commit fc14233036d910e3678d350efc24609e11475067. Original source hashes and license are retained. The local extension adds no vendor code; reserved vendor number 0092 is unused. The J3 draft and Intel references are cited for the independently derived result rules, not incorporated source code.

## Bounded external list input / BACKSPACE

Patch `vendor/patches/0094-procedure-backspace-dispatch.patch` restores the
existing FortFront BACKSPACE parser in its procedure-body dispatcher. No intrinsic
registration changes. The ten original read_alloc_char fixture closures retain
the supplied xutilities bodies and provenance; surrounding drivers are synthetic.

## EOSHIFT original example and local producer change

The unchanged demo_eoshift.f90 and upstream MIT license in tests/eoshift come from
urbanjost/M_intrinsics commit fc14233036d910e3678d350efc24609e11475067. Exact source
and license hashes are retained in upstream.json. Local MIT-licensed producer
patch0095 registers one EOSHIFT identity and reuses keyword-aware ARRAY metadata.
The independent bounded end-shift evaluator is local implementation, not copied
from GNU. Official GNU documentation is cited for behavior, not incorporated code.

## INTEGER bit-intrinsic examples

`tests/integer_bits/cases/demo_{ior,not,btest,iand,ieor,bit_size}.f90` are unchanged M_intrinsics examples from commit `fc14233036d910e3678d350efc24609e11475067`, MIT licensed. Exact source/license hashes and the license text are included in that directory’s `upstream.json` and `UPSTREAM-LICENSE`. Subset rejections and actual execution agreements are reported separately.

## Generic REPEAT and LEADZ producer changes (0.49)

Local MIT-licensed vendor patch 0104 preserves user-generic precedence and adds
bounded intrinsic REPEAT fallback metadata without a registry change. Patch
0105 registers LEADZ once (126 to 127 unique intrinsic names) and resolves its
default-INTEGER result metadata. Their exact deltas and explanations remain in
`vendor/patches/0104-generic-intrinsic-repeat.*` and `0105-leadz.*`. No upstream
authorship or endorsement of the separate interpreter implementation is implied.
