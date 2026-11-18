# Bounded formatted array output

Literal-format PRINT and supported WRITE statements expand INTEGER(4/8),
REAL(4/8), LOGICAL and fixed-length CHARACTER rank-one/rank-two/rank-three items in Fortran
element order (first subscript varies fastest). Whole arrays, sections,
constructors, array expressions, supported array results and assumed-shape
dummies share the ordinary expression evaluator. Empty arrays consume no data
edit descriptor. Mixed scalar/array lists preserve item order.

The flat comma-separated grammar includes: A[w], Iw[.m], Fw.d,
Ew.d, ESw.d, Gw.d, Lw, nX, quoted literals, and the existing scalar DT binding.
Data descriptors accept bounded repeat counts. A repeat prefix on a quoted
literal is invalid and is explicitly rejected. Bounded parenthesized repeat
groups are described in [GROUPED-FORMATS.md](GROUPED-FORMATS.md).
Later bounded extensions add [unlimited/G0](UNLIMITED-FORMATS.md),
[colon](COLON-FORMATS.md), [positioning](POSITION-FORMATS.md),
[B/O/Z](BOZ-OUTPUT.md), [runtime formats](RUNTIME-FORMATS.md),
[finite REAL(4/8) F0.d](F0-FORMATS.md) and external stdout slash edits. Labels, arbitrary format expressions and arbitrary external
units remain unsupported.

When PRINT or positional default-unit WRITE has more values than data edit descriptors, a flat format restarts
on the next record. Grouped formats revert to the last closed group, as specified
in [GROUPED-FORMATS.md](GROUPED-FORMATS.md). When no values remain, processing
ends at the next data edit descriptor or at the end of the format. Consequently, trailing
literals are emitted if reached, but surplus data edit descriptors do not
require extra items. X positioning does not extend a record unless a subsequent
transfer reaches that position. I0.0 output of zero retains the required blank.

Internal WRITE uses a scalar CHARACTER variable or one whole CHARACTER element
of a rank-one/two/three array as one record. Array items are accepted if they
fit that record. Reached format reversion/slash advancement is rejected, and
the target is not committed unless complete formatting succeeds and fits its
length. See [element-file addressing and limits](INTERNAL_WRITE_ELEMENT.md):
whole-array files, sections, substrings, derived output roots and explicit PURE
element files remain excluded. Defined-output child WRITE keeps its separate
one-record callback contract. This adds neither array-valued derived types nor
general external WRITE.

## Validation and safety

- Literal format syntax is validated during compilation for every statement.
- Statically known element counts are expanded for descriptor/type validation.
  Runtime-sized sections, PACK results and dummy/result shapes defer association
  to runtime. Their entire flattened list is type-checked before output.
- At most 64 source items, 65,536 expanded values, and 64 format nodes are
  supported (descriptors/literals plus each inner group boundary). Repeat counts
  are at most 65,536; explicit widths are at most 1,024. A full format cycle's bounded widths/literals must fit 65,536 characters.
- Formatting stages at most 65,536 characters for the complete statement,
  including record-reversion separators but excluding the final output newline.
  This aggregate cap is deliberately stricter than a per-record-only cap.
- Format traversal is bounded to 262,144 operations. Flat non-data repetitions
  are processed in constant time per descriptor; group boundaries and repeated
  group contents count toward the traversal bound. No-data formats with remaining
  values fail rather than loop. Ordinary expression work shares the execution
  budget, initialization checks and array allocation limits.
- Collected CHARACTER output values are capped at 16 MiB per statement before
  formatting. List-directed default output uses a separate 16 MiB completed-record
  cap, including separators, with a bounded geometric-growth buffer. Literal
  formatted output retains the 65,536-character aggregate cap above.
- All PRINT and default-unit WRITE records are staged before the external write, so a later format,
  size, conversion, undefined-value or recursive-I/O failure emits no partial
  output from that statement. Earlier completed statements remain visible.
  An operating-system output failure cannot be rolled back.

## Verification

`tests/formatted_arrays/run_tests.py` compares successful formatted output
byte-for-byte with GNU Fortran, including trailing blanks and record boundaries.
The unchanged M_intrinsics DOT_PRODUCT example compares its formatted and empty
records byte-for-byte; only its final list-directed integer uses token comparison
because processor-dependent padding differs. Cases also cover runtime and
compile-time rejections without stdout, empty arrays, rank-two sections, array
results, constructors, internal records and limits. The native
`test_formatted_arrays` adds AST/IR mutation rejection and direct validator tests.
The suite is part of `scripts/verify.py`.

## Combined runnable example

`examples/allocatable_formatted_arrays.f90` is an exact copy of the synthetic
`tests/allocatable_output/cases/out_inout_result.f90` fixture. It combines
allocatable INTENT(OUT)/INOUT arrays, reallocation, an allocatable PACK result,
flat-format PRINT reversion and internal WRITE. It is new demonstration code,
not a rewrite of the utilities source or an upstream M_intrinsics example.
Its output is compared byte-for-byte with GNU by the combined test suite.

## Later integrated slash capability (0.49)

The exclusions above describe this feature at its original checkpoint, not the
complete 0.49 implementation. Bounded slash record editing now composes with
B/O/Z, groups, unlimited formats, colon, positioning and nonadvancing output.
Scalar internal/defined-child reached record advancement remains unsupported.
The unchanged complete BTEST demo passes all 24 records byte-exact with GNU.
Use `tests/integer_bits/run_tests.py --with-slash-formats` for the integrated
B/O/Z-plus-slash profile; `--with-boz-formats` keeps its earlier capabilities.
See [slash tests](../tests/slash_formats/README.md) for limits and evidence.
