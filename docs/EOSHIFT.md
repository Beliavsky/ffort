# Bounded EOSHIFT

`EOSHIFT(ARRAY, SHIFT [, BOUNDARY, DIM])` supports intrinsic arrays of rank one
or two: INTEGER and REAL kinds 4/8, default LOGICAL, and default CHARACTER with
fixed length from zero through 65536. The result preserves ARRAY type, kind,
shape and CHARACTER length. Existing CSHIFT behavior is unchanged.

SHIFT is INTEGER4/8, either scalar or rank one for a matrix. BOUNDARY is scalar
or rank one for a matrix, with exactly ARRAY's type, kind and CHARACTER length.
Each vector must match ARRAY's shape with DIM removed. Both controls may be
vectors independently. DIM defaults to one and otherwise is a scalar INTEGER4/8
between one and ARRAY's rank. Positional calls and reordered
ARRAY/SHIFT/BOUNDARY/DIM keywords are supported. EOSHIFT is nonreserved, including
scalar, array, function-result, procedure and generic shadows.

Positive shifts discard values from the low-index end; negative shifts discard
values from the high-index end. Omitted BOUNDARY supplies a same-kind numeric
zero, false, or a string of blanks. Amounts at or beyond an axis length fill the
section with the boundary. Shifts are saturated before addition; no negation of
an INTEGER8 machine-minimum input is performed. Each SHIFT and BOUNDARY value is
frozen once per occurrence, not reevaluated for each selected result element.
Selected numeric values must satisfy the existing finite REAL and integer range
policy. Negative real zero is preserved, including a negative-zero BOUNDARY.

Empty arrays retain their declared shape and CHARACTER length. Wrong control
shapes, types, kinds or DIM values cannot be hidden by an empty result. KIND
checks source/IR structure without evaluating ARRAY or controls. Fixed-length
LEN likewise reads descriptors rather than elements or SHIFT values. Cycles,
forged caches, unexpected fields and nondefault CHARACTER metadata are rejected;
shared acyclic operands remain valid. The runtime repeats its own checks rather
than relying on the source adapter.

This bounded implementation rejects rank-three arrays, nondefault CHARACTER,
unknown/deferred ARRAY character lengths, and direct OPTIONAL DIM actuals.
A present optional BOUNDARY works; an absent forwarded BOUNDARY is rejected at
value execution instead of being treated as omission. KIND can inspect absent
optional descriptors without reading their values. These are explicit subset
limits, not claims that all such programs are invalid Fortran.

The existing KIND structural walker does not support derived-component operands.
Consequently a direct component such as `record%shift` in EOSHIFT is currently
rejected at runtime, including under KIND, with `invalid KIND argument opcode`.
Reading that component into an ordinary intrinsic scalar first is supported.
This retained bound is separate from support for intrinsic array elements and
sections; the source check may succeed before the runtime metadata guard rejects it.

The existing one-million-element temporary budget and execution budget remain
active. CHARACTER result storage, frozen boundary scratch and existing cached
CHARACTER values must fit the 16 MiB transformation staging limit. Output still
uses the existing atomic staging, so a failing transformation cannot leak a
partially formatted record.

## Verification

- 141 source outcomes: 103 strict GNU executions, 20 matching source rejections,
  and 18 explicitly compile-only interpreter-bound or machine-boundary cases.
- 5415 direct native assertions, including independent position arithmetic over
  416 matrix/axis/shift combinations, including non-square shapes, metadata mutations, KIND,
  empty arrays, cyclic/shared operands and single-evaluation random-state checks.
- 10 independent producer metadata and source-shadow checks.
- 33 runner adversarial tests, retaining exact Decimal and signed-zero
  distinctions, formatted CHARACTER bytes and truly empty successful stderr.
- 735 related source regressions: CSHIFT90, CHARACTER MIN/MAX106, bounds149,
  constructors99, array intrinsics234 and CHARACTER LEN57.

The official debug app/library was built with `fpm build --profile debug`.
The two native sources were compiled separately with every recorded official
FPM debug flag and linked against that library. No full native aggregate was
run in the feature tree; the release integrator owns that final check.

The full unchanged MIT-licensed M_intrinsics `demo_eoshift.f90`, including its
assumed-shape matrix printer, constructor implied-DOs and runtime formats,
passes byte-exact against GNU14.2. Provenance and source hashes are in
`tests/eoshift/upstream.json`. The [GNU EOSHIFT reference](https://gcc.gnu.org/onlinedocs/gfortran/EOSHIFT.html)
describes the end-off operation and default boundary values.

## Separate machine-boundary observation

GNU14.2 with strict Fortran2018 flags handles both signs of HUGE(INTEGER8) and
shifts beyond default INTEGER range correctly. For `-HUGE(0_8)-1_8`, GNU warns
that the value is outside the standard's symmetric integer model; its runtime
then crashes at both -O0 and -O2 in the retained isolated probe. The interpreter
accepts this representable machine boundary and safely fills with BOUNDARY.
This one source case is explicitly GNU compile-only with independently derived
expected output. It is not reported as GNU execution agreement or as a defect
on a standard-model input. Exact probes and raw outcomes are retained under
`tests/eoshift/oracle-evidence/`; the generic differential comparator is unchanged.
