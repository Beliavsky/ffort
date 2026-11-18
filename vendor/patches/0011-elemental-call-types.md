# Local patch 0011: ELEMENTAL call typing

Upstream: FortFront, https://github.com/lazy-fortran/fortfront, pinned revision
`9a5896a1fce32c394fd02dd1da1bd261ea7a646f`. This local interpreter-project patch
retains the upstream MIT copyright and full license in `vendor/fortfront/LICENSE`.
No upstream endorsement or full upstream ELEMENTAL implementation is claimed.

Apply after patches 0001-0010, from `vendor/fortfront`, with `patch -p1`.
The patch was generated against the exact already-patched vendor baseline and
replayed into a clean copy of all nine touched files. The resulting files
matched the working vendor files byte for byte.

The existing scope-aware interface resolver now identifies ELEMENTAL calls for
result inference, signature collection and result propagation. Call inference
retains the declared result element type and wraps it in the first array actual's
nested shape. Scalar expansion therefore does not depend on actual argument
order, and rank-two calls retain both dimensions. Ordinary function behavior and
intrinsic-specific typing remain unchanged. Scalar procedure result propagation
no longer overwrites ELEMENTAL call results with scalar types or type variables.

Strict argument checking still maps positional/keyword arguments and validates
actual element types. For ELEMENTAL interfaces only, it peels the actual array
wrappers before comparing with a scalar dummy. This also applies to elemental
subroutine interface type checking, without enabling interpreter execution of
those subroutines. Existing dummy, result and purity validation remains active.
The frontend's resolved-type metadata derives the lifted call rank from scoped
actual-expression metadata while copying the declared procedure result type and
kind. This also covers module procedure bodies that generic call inference has
not visited. It synchronizes stale inferred call types without discarding valid
inferred shapes. Keyword values, sections and supported nested elemental
intrinsics retain their actual-expression rank; reductions/inquiries remain
separate. Scoped declared-result inference avoids selecting another module's
same-named private helper.

`test/test_elemental_producers.f90` directly exercises module and internal-main
functions with scalar, rank-one and rank-two actuals, keyword scalar expansion,
a real(kind=8) result from integer arguments, scalar procedure result types,
and rejection of an array with the wrong element type. A same-named private
helper regression checks scalar INTEGER versus elemental REAL(8) helpers in
different modules, including plain, binary, section, keyword/parenthesized,
ABS, conversion, MAX and nested SQRT/conversion actuals. The direct producer test
passes with the pinned local toolchain. The interpreter adapter separately
checks supported types/kinds, scalar dummy/result requirements, argument mapping,
shape conformance and other supported-subset restrictions; this patch does not
claim complete standalone Fortran conformance or disable those checks.

Composition follow-up: strict actual-argument typing preserves the lifted result
of a scoped ELEMENTAL call when it is passed to an ordinary assumed-shape
procedure. Numeric reduction metadata (SUM, PRODUCT, MINVAL, MAXVAL) now derives
rank zero without DIM and rank(source)-1 with DIM, including runtime DIM and
reordered keywords. It does not treat the reduction itself as elemental.
The direct producer regression covers rank-one/rank-two assumed-shape consumers,
SUM with both dimensions and runtime keyword DIM, and scalar SUM without DIM.
The five independent composition fixtures execute with outputs 17; 97;
10 50 122; 82 145; and 82 145, respectively.
