# Bounded default-output unit imports

`use iso_fortran_env, only: output_unit` now works without an INTRINSIC qualifier,
including an anonymous main program. Explicit `use, intrinsic :: ...` and the
optional separator `use :: ...` also work. ONLY renaming retains local and remote
identity, including aliases in main, procedure and module specifications and
existing module/host association.

OUTPUT_UNIT is an immutable scalar default INTEGER parameter whose value is
imported from the host compiler's ISO_FORTRAN_ENV, the same unit already used by
the interpreter's staged stdout backend. It is not a hardcoded Fortran-wide unit
number. The verified GNU 14.2 host uses value 6 and default INTEGER kind 4. The
[GNU ISO_FORTRAN_ENV documentation](https://gcc.gnu.org/onlinedocs/gfortran/ISO_005fFORTRAN_005fENV.html)
defines OUTPUT_UNIT as the preconnected unit denoted by the asterisk in WRITE.
Existing supported REAL32/REAL64/REAL128/INT32/INT64 imports also accept omitted
nature; their kind availability and REAL128=-1 sentinel are unchanged.

With omitted nature, an earlier source-defined module of the same name wins.
Explicit INTRINSIC selects the supported intrinsic module despite that shadow.
Explicit NON_INTRINSIC selects only an earlier source module and never silently
falls back. Module nature is checked independently against the producer's source
module declarations, not merely mutable IR association edges. Existing source
module ONLY visibility and no-forward-use restrictions remain in force.

`write(output_unit,...)` and a verified imported alias route to the same stdout
opcode as `write(*,...)`, retaining the source unit symbol. Existing literal,
named-constant and runtime CHARACTER formats, named UNIT/FMT, list-directed
output, implied-DO items and ADVANCE YES/NO use the unchanged staging/record path.
Position edits, pending-record suffixes, recursive-I/O/purity checks and all work,
value and output-size caps are unchanged. No host filename or arbitrary host unit
is opened. Import metadata and the retained visible unit symbol are independently
validated before execution, even for unused constants and inquiry evaluation.

## Deliberate limits

- A nonempty ONLY list is still required for intrinsic ISO_FORTRAN_ENV.
- INPUT_UNIT, ERROR_UNIT and other unlisted ISO entities remain unsupported.
- OUTPUT_UNIT aliases must satisfy existing nonreserved-name restrictions.
- Whole scalar INTEGER(4/8) names, including ordinary variables, dummies and
  source-module constants, are now admitted by runtime stdout-unit gating only
  when their value equals OUTPUT_UNIT. Literal unit numbers, arithmetic/function
  expressions, elements/arrays, POINTER and ALLOCATABLE unit objects remain
  outside the bounded slice. See [runtime units](../tests/runtime_output_unit/README.md).
- General nonintrinsic module renaming/re-export and procedure-local nonintrinsic
  USE remain outside the existing subset.
- External output remains forbidden inside PURE procedures. No new standard-I/O
  controls, files, error stream routing or asynchronous behavior are added.

For the original import milestone, the only historical test promotion was the unchanged
`tests/iso_env_aliases/cases/implicit_module_nature.f90`: it now succeeds silently.
No existing Fortran source or reference output is changed. The new focused suite
includes the exact user source, normal/explicit nature, source shadowing, aliases,
module/private/host scopes, actual constant kind/value, stdout dispatch, immutable
parameters, unsupported routes, and atomic failures after pending stdout.
