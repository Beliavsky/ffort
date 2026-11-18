# SCAN and VERIFY

`SCAN(STRING, SET [, BACK, KIND])` returns the one-based position of a
character belonging to SET. `VERIFY` returns the position of a character that
does not belong to SET. An omitted or false BACK searches from the left; a true
BACK searches from the right. A search with no matching character returns zero.
Empty STRING always returns zero. Empty SET returns zero for SCAN; VERIFY returns
one for a nonempty STRING, or its length when BACK is true. Blanks are ordinary
characters, and comparisons are case-sensitive.

## Supported contract

- Default CHARACTER operands and default LOGICAL BACK.
- Scalar, rank-one and rank-two elemental operands, including scalar expansion,
  conforming arrays, reverse/empty sections and dynamic dummy shapes.
- Positional and named arguments, including arbitrary keyword order, omitted
  BACK with named KIND, and INTEGER(4/8) constant KIND selectors. KIND defaults to
  default INTEGER(4); the result's shape comes from the elemental data arguments.
- Direct absent OPTIONAL BACK forwarding follows the existing INDEX contract.
  An absent array BACK needs an array STRING or SET to provide the result shape.
- Constant evaluation and unevaluated KIND inquiries preserve validation without
  reading undefined data. Empty results still validate intrinsic metadata.
- Variables, arrays, result names, user functions and generics named SCAN or
  VERIFY retain their ordinary bindings. These names are not reserved words.

Nonconstant, nonscalar and unsupported KIND selectors, invalid keywords,
missing/duplicate arguments, wrong operand types and nonconforming shapes are
rejected. Undefined operands are runtime errors when their values are needed.
This does not add nondefault CHARACTER kinds, wider integer results or I/O.

The independent FortFront producer registers both names and derives their
INTEGER kind and elemental rank from source. The adapter independently checks
argument slots, types and shape against the IR. Runtime validation checks those
contracts again, including malformed IR used only through KIND or empty arrays.

## Utility source and verification

The untouched xutilities file calls SCAN in `get_numbers` at lines 9454 and 9499.
A new driver retains those two expressions with their source hash and line map.
It is not the original routine: that routine still needs unsupported I/O and
other declarations. The whole utilities file remains unsupported, and its
original bytes are not changed by this milestone. VERIFY is a related shared
language dependency rather than an additional original utility call.

`tests/character_search/run_tests.py` checks 58 cases: 24 native GNU comparisons,
28 invalid-source rejections and six GNU compile-only cases for undefined values
or the interpreter's narrower kind model. One comparison covers all 2,080
combinations of SCAN/VERIFY, strings of length zero through three and sets of
length zero through two over `a`, `b` and blank, in both search directions.
Expected positions are computed by an independent Python character-membership
model, with positional/named forms and INTEGER(4/8) selectors interleaved.

`test_character_search` checks adapter/runtime mutations and empty paths (330
assertions). `test_character_search_producer` independently checks 18 producer
metadata and shadowing cases. The existing character-intrinsic suite remains a
separate regression suite for INDEX, LEN_TRIM, ADJUSTL and ADJUSTR.

Semantics were checked against the official GNU documentation:
[SCAN](https://gcc.gnu.org/onlinedocs/gfortran/SCAN.html) and
[VERIFY](https://gcc.gnu.org/onlinedocs/gfortran/VERIFY.html).

## 0.28 composition

The rank-three ordinary-array extension also applies to elemental SCAN/VERIFY. Release composition checks cover rank-three strings with optional rank-three BACK and rank-reduced WHERE masks. WHERE itself remains rank one/two.
