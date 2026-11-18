# Bounded multi-object allocation and deallocation

ALLOCATE and DEALLOCATE accept one through 64 whole allocatable arrays in one
statement, with one optional trailing STAT scalar. Existing INTEGER(4/8),
REAL(4/8), default LOGICAL and default CHARACTER arrays of ranks one through three
retain their declaration, shape and resource limits. Different supported types
and ranks can share an untyped ALLOCATE list. A shared CHARACTER(LEN=...) type
specification applies only to deferred-length CHARACTER objects, as before.

## Ordered effects and STAT

This interpreter chooses left-to-right execution and stops on the first
allocation-status failure. Successful earlier objects retain their new allocation
status. The failed object keeps its old descriptor and contents; later objects
are not touched. STAT is assigned once after the statement, zero on success and
a positive processor-dependent value on allocation/deallocation failure. Do not
depend on the specific positive code. Without STAT, failure raises a checked
runtime error and stops execution. There is no transaction rollback.

This is permitted by Fortran 2018 draft 18-007r1 section 9.7.4 paragraphs 4–6;
section 9.7.3.1 paragraph 4 explicitly leaves deallocation order processor
dependent. The particular successful-prefix policy is an implementation choice,
not a portable guarantee of Fortran source. Strict GNU 14.2.0 probes at -O0/-O2
agree with the chosen prefix/suffix states for ordinary numeric objects.
Primary reference: https://j3-fortran.org/doc/year/18/18-007r1.pdf

Invalid IR metadata and effects are checked across the full group before any
object is changed. Ordinary allocation failures, such as an already allocated
object or an unallocated DEALLOCATE object, are handled per object during ordered
execution. Arithmetic/undefined-value/budget failures remain interpreter runtime
errors, not STAT-recoverable allocation errors. Existing element, CHARACTER byte,
expression, call-frame and execution-budget limits are unchanged.

## Bound dependencies and bounded syntax

Every object must be distinct and writable. Bounds and shared CHARACTER length
must be scalar INTEGER expressions. This multi-object subset rejects every nested
reference to an allocation-list object or to STAT, and rejects user-function calls
in bounds/length expressions. The implementation therefore cannot observe a
changed allocation status or STAT value while evaluating a later bound.

The standard forbids allocation bounds/type parameters/object designators that
depend on allocation-list objects or STAT (section 9.7.1.1 paragraph 2), and imposes
STAT restrictions in section 9.7.4 paragraph 3. Our syntactic exclusion is more
conservative: even harmless KIND(array) references to a listed object, and PURE
user-function bounds, remain unsupported. GNU accepts some nonconforming STAT
references, so its compilation is not used as proof that those sources are valid.

SOURCE, MOLD, ERRMSG, pointer allocation, scalar allocatables and new type-spec
forms remain unsupported. Single-object execution and its existing expression
contract are preserved. The extension does not add asynchronous effects, object
finalization or derived/polymorphic allocation.

## Representation and independent guards

A group retains one ordinary instruction per object, preserving each symbol for
existing purity, module/host-effect and alias analyses. Adjacent instructions
carry a bounded count, one-based ordinal and exclusive group end. Single-object
instructions retain their previous zero group fields. The adapter independently
matches every source object, bound, length, STAT and declaration identity.

The runtime rejects malformed counts, order, endpoints, frame crossings, entry
into a group interior, duplicate targets, inconsistent fields and invalid operand
trees before executing the first object. The dependency walker memoizes shared
DAG nodes and rejects cycles and excessive depth. Every object still uses the
existing storage, descriptor, CHARACTER, allocation-cap and owner/lifetime code.

Vendor patch 0073 recognizes STAT/ERRMSG/SOURCE/MOLD as options only when followed
by '='. These names can therefore remain ordinary allocation objects. DEALLOCATE
binding validation uses the same checked lexical scope as ALLOCATE, including
DO/IF bodies that do not introduce a Fortran scoping unit.

## GNU caveat for failed CHARACTER allocation

GNU 14.2.0 changes the length descriptor of an already allocated deferred-length
CHARACTER object during a failed typed allocation, despite retaining its prior
size/data. FortFront preserves the failed object's old length, bounds and contents
under the section 9.7.4 partial-result rule. That focused case is explicitly
specification-based, with GNU compile-only evidence, not an execution agreement.
User-function evaluation-count differences for shared LEN expressions are avoided
by the stated function-free bound/length restriction.

## Verification and historical fixtures

The focused suite contains 49 cases: 27 GNU executions, 12 compile-only cases
(including resource/subset boundaries and the CHARACTER descriptor caveat), and
10 GNU compilation rejections. One successful CHARACTER case is specification-
based. The new native program adds 593 metadata, DAG, descriptor, prefix-state,
frame, purity/effect, boundary and repeat-execution assertions. The runner has
14 self-tests. GNU compiles in a fresh temporary directory with
`-std=f2018 -pedantic-errors -fcheck=all -O0`.

The unchanged `tests/allocatables/cases/allocate_two.f90` is promoted to successful
GNU execution without output. The unchanged CHARACTER SOURCE-option rejection
keeps its rejection and uses the clearer SOURCE/MOLD/ERRMSG diagnostic expectation.
No existing Fortran program fixture is modified. Exact uploaded xmix_dt execution
and its numerical invariants are verified separately by the combined-release
harness; this feature's standalone tree does not contain the independent REAL fix.
