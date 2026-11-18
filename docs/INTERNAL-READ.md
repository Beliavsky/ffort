# Internal READ contracts in 0.56

The scalar input-file contract below is retained as historical documentation. The separate [local CHARACTER element contract](INTERNAL-READ-ELEMENT.md) defines the new bounded input-file branch. In the producer PURE context, the new element exemption permits only whole scalar nonallocatable intrinsic INTEGER/REAL/CHARACTER targets and scalar INTEGER IOSTAT with verified local or permitted OUT/INOUT storage. Do not read the historical broad PURE wording below as a promise that every scalar or array target is accepted in every producer scope: the existing program-contained versus module-contained scalar-PURE context limitation is not generalized or repaired by this change.

## Preserved scalar internal-READ documentation

# Bounded internal list-directed READ

This extension reads a single scalar default-CHARACTER variable as an internal
record. It does not open a file or read standard input. Explicit bounded external
A-format records are documented separately in [EXTERNAL-READ.md](EXTERNAL-READ.md).

```fortran
read(text, *, iostat=status) count, values
read(unit=text, fmt=*) values
```

UNIT and FMT may be named in the illustrated order; optional IOSTAT follows them.
Each input item is a whole INTEGER(4/8), REAL(4/8) or default CHARACTER variable or allocated array of
rank one through three. Arrays are traversed in Fortran column-major order.
There are at most 64 syntactic input items and at most the configured element cap
of expanded data targets. Empty lists and zero-size arrays require no values.
IOSTAT is a distinct writable scalar INTEGER(4/8) variable, not an input item.

Procedure targets must belong to the current activation and must not be SAVE
variables. Local variables and INOUT/OUT dummies are supported. Main-program
variables, including initialized variables, are supported. Internal READ therefore
works in ordinary, PURE and SIMPLE procedures without relaxing existing external
I/O restrictions. Existing call, alias, absent-OPTIONAL and active-DO protections
remain in force. Names such as READ and UNIT remain usable as declared variables
or procedures, including array-element and substring assignments.

## Data transfer and errors

The supported record syntax includes decimal integer/real values, signs, E/D and
implicit real exponents, blank/tab/comma separators, positive repeat counts,
repeated nulls, and slash termination. Nonnull repetitions must keep the same input type and kind. Nulls and slash-preserved items retain both
their old value and their old definedness. Unused trailing input is not converted.
Each execution starts again at the beginning of the internal record. Repeat
counts are bounded by INTEGER(8), and repetitions are consumed lazily, not expanded
into a temporary array.

IOSTAT is zero on successful completion, -1 on end of the scalar record, and 1
on malformed numeric input, conversion overflow or a nonfinite result. Positive
error numbers are processor-dependent; only their sign is compared with GNU.
GNU accepts some real overflow/nonfinite values that this interpreter deliberately
rejects, so those safety-policy cases are compile-only GNU references.

Transfers happen in list order. On conversion error or EOF, all data-list objects
become undefined, including any prefix that transferred and any old values.
Storage is not rolled back, but incidental stored values cannot subsequently be
read as defined. This follows F2018 sections 12.11.2 and 12.11.3 in the
[J3 interpretation document](https://j3-fortran.org/doc/year/18/18-007r1.pdf).
Without IOSTAT, an input error or EOF is a checked runtime error. Metadata,
unallocated/absent targets, undefined input records, overlap, active loop-variable
writes, and exhausted work budgets are interpreter safety errors, not recoverable
IOSTAT results. All target descriptors are validated before data transfer.

Records are at most 65,536 characters. The full record length and each effective
input item consume work budget, including null/repeated values. The numeric lexer
uses fixed bounded scratch storage; no external data service or compiler is used
at execution time. Native Fortran internal conversion is used only for individual
validated numeric tokens, in the target's actual kind. Signed zero, INTEGER(8)
precision and REAL(4) rounding are retained. Resource caps are unchanged.

Rank-one section targets are now covered by the separate [READ sections contract](INTERNAL-READ-SECTIONS.md). The historical whole-object error rule applies to the selected elements only for a section target. Existing producer PURE restrictions are unchanged.

## Deliberate exclusions

Implicit host units, stdin, CHARACTER arrays as internal files, literal/parameter or
compound file expressions, arbitrary control order, explicit formats, IOMSG,
ERR/END/EOR, ADVANCE/SIZE/DECIMAL controls, NAMELIST, implied DO, target elements, LOGICAL/COMPLEX/derived targets, POINTER targets, repeated or
aliased targets, and nonlocal or saved procedure targets remain unsupported.
Embedded control characters other than tab are rejected rather than interpreted
as extra records. This is bounded list input, not full Fortran READ. CHARACTER quoting, repetition and limits are described in EXTERNAL-READ.md.

## Original utility bodies

The fixtures retain exact CRLF bytes of read_int_vec_alloc (xutilities lines
4197–4216) and read_real_vec_alloc (4218–4237). Wrappers and callers are new;
original implementations are not rewritten. Positive, zero-size, negative-size,
repeat-value and initial count-error paths are covered.

Two original failure paths use n after the second READ reports an error. That n
is undefined by the input statement. FortFront consequently reports an
uninitialized read while preparing the original error message. GNU compilation
is recorded, but its incidental n value is not used as an execution oracle.
Likewise, null counts or slash-preserved uninitialized array elements are guarded.
This is an explicit source limitation, not an invitation to disable definedness.

The unchanged full utility source still contains xbig(10**8), beyond both the
one-million default and ten-million opt-in configurations. A separate diagnostic
copy reducing only that declaration still encounters the independent character
operator boundary on the 0.42 baseline. Neither full-source checking nor complete
utility-library execution is claimed by this extension.

## Verification

The feature suite has 81 source cases: 37 GNU execution references, 37 GNU
compile-only subset/safety references, and seven GNU compilation rejections.
Ten wrappers retain both exact original bodies. The harness has 20 adversarial
checks, exact Decimal token comparisons (including signed zero and large
integers), byte-exact optional text modes, truly empty successful diagnostics,
and exact STOP exceptions only for the two original initial count-error cases.
Native coverage includes 224 public-IR/runtime/adapter checks and 11 independent
producer checks. These focused results are separate from the release integrator's
full clean verification.
