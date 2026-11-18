# Contextual CHAR names

CHAR may now be a declared data, dummy, result, function, generic or component
name. The existing source parser resolves visible declarations before intrinsic
calls. This change removes CHAR alone from its broad reserved-name list; it does
not generally unreserve Fortran keywords or all intrinsic spellings.

Supported regression cases cover scalar INTEGER and CHARACTER data, rank-one
INTEGER/CHARACTER arrays, rank-two sections, CHARACTER substring reads/writes,
parameters, optional and mutable dummies, actual keyword `char=`, explicit and
implicit function results, module data, local/host shadowing, generic functions,
components and mixed case. Unshadowed CHAR retains positional/keyword and KIND
handling, constant evaluation, and elemental array conversion. Declared scalar
data cannot silently fall through to intrinsic CHAR when followed by arguments.

No producer or runtime code changes are needed. The independent adapter still
verifies exact declaration identities, argument association and result metadata.
It now also rejects an intrinsic CHAR IR node if the original source's scope
resolves CHAR to a declaration. This additional check prevents a same-result-type
user function or generic from being forged as the intrinsic merely because its
name and argument types happen to match. The source binding query and independently
matched symbol table are used, not the producer's lexical intrinsic hint.

## Original utility evidence

The exact `positions_char_string` body at xutilities lines 8812–8822 executes with
its exact original `true_pos_func` and `set_alloc_int_vec` dependency bodies.
Synthetic scaffolding narrows the two generic interfaces to these exercised
specifics. All original routine bytes, including CRLF, are verified with hashes.
The seven driver calls agree with GNU using strict Fortran 2018 and runtime
checks; the original FORALL produces GNU's standard obsolescence warning.

This is a focused original dependency closure, not a claim of full xutilities
module support. General module-data USE renaming remains a separate documented
boundary. Other reserved names, general INTRINSIC/EXTERNAL declarations and
procedure dummy arguments retain their existing limits. See
`tests/char_identifiers/README.md` for tests and reproduction commands.
