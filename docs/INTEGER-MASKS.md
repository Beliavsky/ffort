# Bounded INTEGER masks and logical right shift

This bounded implementation adds `MASKL(I[,KIND])`, `MASKR(I[,KIND])`, and `SHIFTR(I,SHIFT)`.
It does not extend supported INTEGER kinds beyond 4 and 8.

## Contract

* `MASKL` sets the leftmost I bits; `MASKR` sets the rightmost I bits.
  The other bits are zero. I is INTEGER(4) or INTEGER(8), scalar or
  rank 1–3. KIND is an optional scalar INTEGER constant expression whose
  value is 4 or 8. The result defaults to INTEGER(4), **not the kind of I**.
  I is in 0..32 for result kind 4 or 0..64 for result kind 8.
* `SHIFTR` shifts the bit pattern of I right, introducing zeros on the left.
  I and SHIFT are INTEGER(4/8), with independent kinds; the result has I's
  kind. SHIFT is in 0..BIT_SIZE(I). The supported elemental shapes are
  scalar or conforming rank 1–3, including scalar expansion and empty
  arrays. Reversed keyword order preserves I's type/kind metadata.
* A zero count returns zero for masks and the unchanged bit pattern for
  SHIFTR. A full-width mask is all ones (-1 in the supported representation);
  a full-width shift is zero. Count bounds are checked in INTEGER(8) before
  narrowing or invoking width-specific host operations. No floating-point
  conversions, absolute values of signed minima, or overflowing signed
  arithmetic are used to construct these bit patterns.
* Runtime values outside the stated count range are controlled interpreter
  errors. Undefined values and unallocated operands are not silently read.
  KIND inquiries validate metadata without evaluating the value operand;
  a mask's result selector remains a checked constant even under KIND or
  when the elemental result is empty.
* Existing argument association, shape, array limit, expression-cycle,
  declaration/literal cache and component restrictions remain in force.
  The adapter and public-IR runtime independently validate result kind and
  selector metadata. Ordinary same-named procedures retain precedence.

The mask/shift increment did not add small-kind storage, ISO import expansion
or TRAILZ. The separate [TRAILZ/ISO extension](TRAILZ-ISO-INTEGER-AVAILABILITY.md)
adds trailing-zero counts and availability constants only; INTEGER(1)/(2), BOZ
conversion, SHIFTL/SHIFTA, POPCNT and POPPAR remain outside the contract.

## Historical mask-milestone upstream examples

Pinned M_intrinsics commit: `fc14233036d910e3678d350efc24609e11475067`.
Original bodies are retained without edits under `tests/integer_masks/cases`.

| Example | Source SHA-256 | Intended outcome |
|---|---|---|
| MASKL | `3c84ba02e3513f2f502137e09530922983e43c8e25d661c2f8aef089cd587aeb` | Full run, all 441 GNU stdout bytes exact |
| MASKR | `01194391b7c03d1fa0ca110199792a717350ff851c2ea5a643b6fea4e540fbf2` | Full run, all 1,838 GNU stdout bytes exact; includes SHIFTR |
| SHIFTR | `a06f8bbf5be3a35cb385f9f03bb20806391bc2d8b4d60e45c8831cc2ede1f57a` | Still rejected at ISO INT8/INT16 imports; actual INT8 and BOZ use also remain outside scope |

Corrected combined-preview validation passed these outcomes on CLI SHA256
`3e9c191de0f548e9dc8fc189c3d579e4fde4dbc2617c0b43170add660ca04a19`.
The full focused suite has 164 contracts: 113 successful programs, 30 exact
static boundaries, and 21 exact controlled runtime errors. GNU independently
executes 125, compiles but does not execute 21 undefined/out-of-range cases,
and rejects 18. GNU-valid kinds 1/2/16 remain distinct from invalid Fortran.
Full raw commands and outputs are retained. These are focused results, not
full-release certification.

## Verification

The focused source suite uses an independent Python arbitrary-precision
integer oracle, exact record/token shape and exact integer values. Only
horizontal spaces in ordinary integer/logical list-directed records may
vary. Real-looking numbers, nonfinite values, added/deleted records, tabs,
missing final newlines, extra output and crash markers fail. The two passing
upstream format-heavy examples instead require full byte equality, preserving
record separators and padding.

The native `test_integer_masks` checks public-IR mutations in ordinary,
KIND and empty-array contexts, literal/parameter selector caches, and
independent exact values at every shift/mask count for both supported widths.
It passes 5,747 assertions against the matching central library. The unchanged
old integer-bit suite (9,709), producer suite (56) and LEADZ suite (1,013) also
pass. The initial native failure and unchanged reproducer are retained: a
forged scalar PARAMETER cached kind had been accepted. The final bit-tree
metadata guard rejects it, while separately named mixed-kind PARAMETER
initialization conversions remain valid.

Primary descriptions:
- https://gcc.gnu.org/onlinedocs/gcc-13.3.0/gfortran/MASKL.html
- https://gcc.gnu.org/onlinedocs/gfortran/MASKR.html
- https://gcc.gnu.org/onlinedocs/gfortran/SHIFTR.html

## Preserved first evidence

The first 146 source bodies and expectations are preserved. Six rank-three
fixtures initially assumed rank-three RESHAPE support and failed before the
bit call. They remain exact inherited-boundary cases; six separately named
ordinary-assignment fixtures prove rank-three bit operations without extending
RESHAPE. Twelve additional named scalar/array PARAMETER conversion fixtures
cover INTEGER(8) initialized by default INTEGER literals (both explicit _4
and unsuffixed) and INTEGER(4) initialized by fitting _8 literals, as mask
KIND, mask count and SHIFTR shift. No original source was rewritten.

## ISO-import progression

INT8/INT16 availability imports alone no longer denote small-kind implementations: the processor values are -1, and INTEGER_KINDS is [4,8]. The original SHIFTR program still requests unsupported small-kind/BOZ operations. Its historical import diagnostic above may advance, but no whole-SHIFTR success is claimed. Final expected diagnostics belong to separately measured test migrations, not this prose overlay.
