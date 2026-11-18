# Bounded internal list-directed READ section targets

This 0.57 development checkpoint extends the existing internal READ contract to
writable rank-one array sections, for example:

```fortran
read(text, *, iostat=ierr) xread(:i)
read(text, *, iostat=ierr) a(5:1:-2)
```

The input file and controls retain the [internal READ](INTERNAL-READ.md) and
[CHARACTER element input-file](INTERNAL-READ-ELEMENT.md) restrictions. This does
not extend external READ, formats, array-valued input files, or producer PURE
scope exceptions.

## Supported targets and addressing

Sections may select existing INTEGER(4/8), REAL(4/8), or default CHARACTER array
storage, fixed or allocated, including existing permitted OUT/INOUT array dummy
storage. CHARACTER length 100 and assumed-shape procedure targets are covered.
Each section is rank one; vectors, parenthesized targets, pointers, optional
storage and INTENT(IN) destinations remain excluded. Existing local ownership
and alias protections are retained, including source and IOSTAT separation.
Repeated target symbols are rejected, even for disjoint sections.

Bounds and stride may be omitted, integer literals, or bounded scalar
INTEGER(4/8) arithmetic expressions using independent variables and +, -, *, /,
**. They may not depend on IOSTAT or any input-list target. This deliberately
excludes sequential target-dependent addressing instead of silently evaluating
it early. Calls, vectors and higher-rank sections are outside this contract.

All descriptors, bound expressions and actual selected offsets are checked and
frozen before input transfer. Addresses are recomputed for every READ execution,
including repeated statements inside a loop. Zero stride and invalid selected
offsets fail before any target or IOSTAT changes. Empty sections transfer no
items; an endpoint outside storage is allowed when no selected offset is out of
range. Existing element, item, byte and execution caps remain in force.

Omitted endpoints use the declared lower and upper bounds regardless of stride
sign, matching the existing section engine and GNU checks. Consequently, for
`a(1:5)`, `a(::-1)` is empty; `a(5:1:-1)` reverses all five elements. Negative
strides transfer in section order, not base-array order.

## Transfer and failure behavior

Null items and slash termination preserve selected values and definedness.
Successful assignments define only the selected cells. Conversion or end-of-file
errors retain the existing READ policy: input-list objects become undefined;
for a section, only its selected cells become undefined. Unselected base-array
cells remain unchanged and defined. This is not transaction rollback, and
incidental selected storage after an error must not be read as a result.
IOSTAT is zero on success, negative on end-of-file, positive on conversion error.
Without IOSTAT, an input error is fatal. Descriptor preflight failure does not
start input transfer and does not assign IOSTAT.

## Verification and utility boundary

Author tests comprise 18 batch transcript cases and 45 native checks.
Independent verification covers 32 GNU differential cases, 18 failure/definedness
cases, four procedure cases and 146 native checks. GNU comparisons on failed
input examine status sign and unselected cells, never undefined selected values.
These focused checks are separate from full-suite certification.

The unchanged authorized utility working source now reaches 3550:30,
`jmat=imat(jrow_use,jcol_use)`, beyond numeric and CHARACTER `xread(:i)` READs.
Both check and run stop before execution because both matrix axes use vector
subscripts. No complete utility-program execution is claimed. Exact source and
candidate identities appear in the [utility README](../tests/utilities_working/README.md)
and the separate `candidate02-utilities.json` checkpoint evidence.
