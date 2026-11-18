# Bounded external `(A)` READ into a CHARACTER array element

This extends the [registered external input](EXTERNAL-READ.md) contract with a single complete scalar element of a rank-one, rank-two or rank-three default-CHARACTER array:

```fortran
integer :: unit = 27, status
character(4) :: lines(2)
lines = '----'
read(unit, '(a)', iostat=status) lines(2)
```

With unit 27 explicitly bound to a record `xy`, successful input leaves `lines(1)` unchanged and sets `lines(2)` to `xy` followed by two blanks. The interpreter does not open a filename named by the Fortran source. `--check` does not open bound input files.

## Target, indices and effect restrictions

The target is one complete CHARACTER element, not a section, vector-subscripted selection or substring. Only a literal A-only format, exactly one target, a scalar INTEGER unit variable and optional scalar INTEGER IOSTAT are accepted. List-directed element targets, explicit widths such as `(A2)`, multiple items and runtime formats remain excluded.

Fixed, allocated deferred-length and supported runtime-length local arrays are covered. Existing supported writable dummy-array contexts retain their bounded ownership, intent, alias and presence checks; the focused suite includes an assumed-length `CHARACTER(*)` dummy. A nonallocatable runtime-length `CHARACTER(n)` dummy is still rejected at its declaration. That earlier unsupported-source boundary is not a passing READ capability. Pointer targets, host/module writes and prohibited effect contexts are not newly admitted. External input remains disallowed in PURE/SIMPLE procedures and ordinary functions.

Every index must be a supported scalar INTEGER expression. User-function references, including PURE calls and calls hidden in constructor metadata, are excluded. An index depending on the IOSTAT destination is excluded: this implementation does not claim a universal processor-independent order for that combination. Intrinsic inquiry expressions are permitted only within the existing supported expression and metadata rules.

Index metadata, type/kind/rank/shape caches and expression ownership are checked before evaluation. Each index is evaluated once to freeze the selected address before input cursor, target or IOSTAT commit. Bounds, allocation, target length and storage checks occur before transfer; an undefined target element need not be read to obtain its address.

## Transfer and failure behavior

Existing record rules are unchanged: LF/CRLF records, optional final unterminated record, blank padding, truncation, zero-length targets and complete record consumption. CHARACTER length and record length remain bounded by 65,536; existing aggregate input, storage and work-budget limits still apply.

A successful transfer stages the CHARACTER value and then commits only the selected element and its definedness flag, followed by input position/status changes. Other elements and their definedness are not overwritten. EOF makes the selected target undefined while leaving neighboring elements unchanged. Existing EOF, endfile and BACKSPACE behavior is retained. Binding, bounds, metadata and resource violations remain safety diagnostics rather than recoverable IOSTAT values. Earlier successfully committed operations are not rolled back.

`INQUIRE(..., NAME=...)` remains a whole writable scalar CHARACTER target; it does not inherit this READ-element extension. Internal READ with an array-element input file, internal substring files and writable substring READ targets remain outside this checkpoint.

## Verification status

The source suite preserves all original 66 fixtures and adds a separately named runtime-length local-target fixture. Its reviewed successor distinguishes 25 exact diagnostic pins, one length-65,536 composition promotion enabled by existing substring expressions, and one correction of an optimistic runtime-length-dummy expectation. Original expectations and first observed failures are retained, not relabeled as original passes. GNU executions, compile-only cases and measured compiler rejections remain separate.

The clean 0.55 maintained run passed all 67 source contracts (44 GNU executions, 20 compile-only cases and 3 GNU rejections) and the native test's 447 assertions. These current results do not erase the preserved preview failures or imply support for excluded targets. See [release scope](RELEASE-0.55.md) and [measured verification](VERIFICATION.md).
