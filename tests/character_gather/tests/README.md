# CHARACTER vector gather fixtures

24 fixtures: 23 original reconstructed fixtures and one aggregate live-cache cap case.
GNU Fortran compiles24 and executes17; seven remain compile-only to avoid undefined
reads/out-of-bounds execution or to describe retained supported-subset exclusions.
Original_dependency_closure contains original select_vec_character,
set_alloc_character_vec and set_optional_integer procedure bodies (line endings
normalized), plus narrowed generic interfaces, restated mod_str constant and driver.
The synthetic allocatable_resize fixture is separate, not proof of complete utilities.

Semantics covered: repeated and out-of-order indices, nonunit lower bounds, overlap,
empty and zero-length arrays, PARAMETER, undefined selected versus unselected values,
metadata-only LEN/KIND with undefined indices/unallocated fixed-length bases,
assumed/deferred lengths, reallocating alias targets, typed/fixed constructors,
and per-iteration release of gather string-cache byte charges.

Numeric rank-one, CHARACTER rank-two, scatter assignment, and dynamic-length
untyped CHARACTER constructor nesting remain intended boundaries. Focused c7501595 preview validation passes all24 cases; release certification remains separate.

Direct derived-component selectors, for example CHARACTER x([r%n,1,r%n]), are valid Fortran but remain an explicit exclusion in this checkpoint: CHECK succeeds and execution rejects with 'invalid KIND argument opcode'. This is a CHARACTER-gather metadata-length-path limitation, not an inherited numeric-gather restriction; the numeric rank-two counterpart succeeds on both 0.51 and this preview. Assigning n=r%n first and selecting with n works. The exact original select_vec_character dependency closure is unaffected.
