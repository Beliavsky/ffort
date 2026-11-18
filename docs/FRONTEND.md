# FortFront adapter and local corrections

Array reductions and vector/matrix products added in 0.11.0 are documented in [ARRAY-INTRINSICS.md](ARRAY-INTRINSICS.md).
The vendor source is FortFront commit `9a5896a1fce32c394fd02dd1da1bd261ea7a646f`
(MIT), with targeted corrections recorded in `vendor/patches/` and described
below.
The upstream checkout used in the evaluation was not modified.

## Version 0.41 integration

The private IR and independent adapter validate the bounded inverse-trigonometric
contracts, scalar CHARACTER PARAMETER format bindings and explicitly typed empty
numeric/logical constructors. Named formats do not add a mutable runtime-format
path. Typed empty metadata remains distinct from an untyped empty expression.
Cumulative vendor patch 0074 supplies inverse-trigonometric producer metadata and
ATAN2 registration; 0076 preserves empty-constructor element-kind metadata.
Patch 0075 is unused. Resource limits and the complete original utility boundary
are unchanged. See the feature manuals and `VERIFICATION.md` for evidence.

## Admission contract

1. `fi_parser` consumes the entire original source using a deliberately restricted
   grammar. It builds a private typed IR and rejects unsupported syntax and
   invalid operand/assignment types, including in unreachable statements.
2. `fi_frontend` calls FortFront's STANDARD/STRICT compiler API with semantic
   analysis enabled and source rewriting disabled. Failure is fatal.
3. The adapter verifies that all IR symbols have scalar, rank-one or rank-two declarations
   of matching supported type, kind and bounds, and all IR executable source statements are represented
   in the AST. It recursively compares literal values, identifier names and
   resolved declaration identities, unary/binary operators and intrinsic arguments for
   declaration initializers, assignments, PRINT, IF conditions and DO controls.
   Unexpected AST node kinds and incomplete binary expressions are rejected.
4. Only the independent IR reaches the execution engine. The runtime holds no
   FortFront arena pointers and never compiles the interpreted source.

This is a dual-parser safety boundary, not a claim that FortFront now validates
all Fortran. The private parser determines control-flow layout and semantic
restrictions. FortFront is a required independent structure/binding/type check,
not the execution representation. The adapter deliberately uses public
`fortfront_compiler` queries and the concrete AST types exposed by
`fortfront_ast`; it is tied to the pinned revision, not a stable external ABI.

## Version 0.3.0 program forms and named constants

The source recognizer accepts standard main programs without a PROGRAM statement,
optional IMPLICIT NONE, and bare END. It still requires explicit declarations for
all variables, rejects multiple units, and checks any END PROGRAM name against an
explicit header. No source wrapper, synthetic declaration, or line-number rewrite
is passed to FortFront. For an anonymous main, the adapter checks the pinned
frontend's synthetic `main` program name. Its retained `end_statement_node` must
match the source recognizer's final END line and column. That synthetic name does
not reserve a source variable named `main`.

Scalar INTEGER, REAL and LOGICAL PARAMETER attributes are matched to the declaration
query. Initializer expression trees and exact named-constant bindings are checked
as for variable initializers. The bounded constant evaluator converts each value
to its declared type; the adapter recomputes and compares the cache, including
logical and real values. Parameters do not become assignment instructions, and
both source admission and the runtime reject assignment or DO control using one.
Earlier parameters may appear in initializers and explicit array bounds. Ordinary
variables, self/forward references, and array parameters remain outside this
constant-expression contract. Native regressions deliberately mutate parameter
flags, readiness, cached values/types and expression trees and require rejection.

No further vendored changes were needed for these features. Integer exponentiation
already had checked integer arithmetic, right association and correct unary-sign
precedence; the requested `2**5` example was blocked by program-form admission,
not a floating-point power calculation. New source and GNU differential tests
exercise it through the complete pipeline.

## Correction 1: default REAL and process-global mode

At the pinned revision, resolved-type annotation consults standardizer mode, but
`compile_frontend_from_string` only sets that mode when rewriting is requested,
after initial semantic annotation. Raw STANDARD calls can therefore report
REAL kind 8 instead of kind 4 and inherit a preceding call's mode.

The local correction sets the selected input mode at the start of every compiler
API invocation, before parsing/semantics/metadata annotation. It does not make
FortFront thread-safe. Calls in one process must remain serial. The regression
executes seven STANDARD/LAZY, raw/standardized permutations, beginning with a
fresh STANDARD/raw call, and asserts REAL kind and storage width each time.

## Correction 2: CHARACTER length is not kind

The parser uses a legacy `kind_value` field to store CHARACTER length in some
declarations. The declaration type query previously trusted that value, making
`character(len=8)` appear to have kind 8. For CHARACTER declaration metadata,
the correction now resolves the dedicated kind-selector expression when present
and otherwise uses default character kind 1. Length remains separate and is
not used as kind. The regression covers LEN alone and both LEN/KIND keyword
orders, plus explicit kind 4 in both keyword orders. This targeted correction does not claim full CHARACTER support or
repair every character-related query. Current fixed-length scalar/array support is
described in [CHARACTER-ARRAYS.md](CHARACTER-ARRAYS.md).
Version 0.7.0 supports scalar assumed-length CHARACTER INTENT(IN) dummies.

## Malformed expression containment

Upstream accepts `x=(1+)` with an incomplete binary AST. The strict source parser
rejects it before FortFront is called. The adapter additionally rejects missing
binary operands. A direct adapter regression supplies a deliberately inconsistent
IR for this malformed source to prove that the adapter cannot admit it merely
because the upstream compiler API returns success. Separate adapter tests reject
an AST/IR literal mismatch and admit the corresponding matching assignment.

The prototype does not support nonintrinsic module USE renaming, generic interfaces, general
array ranks, or other out-of-subset constructs. These are rejected by the source
guard, rather than passed through. Version 0.7.0 adds the bounded access-control
and procedure argument checks described below.
The supported rank-one element case has the narrow structural accommodation below.

## Single-scope binding accommodation

The pinned frontend can leave parent/scope links unavailable for references in
nested DO bodies or DO bounds/stride expressions. If identifier-relative
resolution fails, the adapter calls the public `resolve_name_in_scope` query for
the sole root PROGRAM. It requires the result to be the exact declaration node
already matched to that IR symbol, then checks that declaration's type/rank/kind.
This is sound only because the source guard excludes every construct that can
introduce another scope, association or implicit declaration. It is not a general
fix for FortFront scope resolution. A nested-loop/variable-stride regression
exercises this accommodation. No unresolved binding is admitted.

## Case-insensitive semantic scope keys

The array extension exposed a producer-side bug: `INTEGER :: Values(-1:0)`
followed by `vALues(-1)=7`, `VALUES(0)=9`, and reads with other casing was
treated as calls to undeclared procedures. Semantic scope definition and lookup
used case-sensitive identifier-table keys, so the array-call resolver failed to
find the declared array. Patch `0002-case-insensitive-semantic-scope.patch`
normalizes keys with `to_lower` at both scope operations. Source text and AST name
spelling are preserved, and the general-purpose identifier table is unchanged.
The native array adapter test and independent mixed-case differential case cover
the regression. This is a targeted semantic-scope correction, not a claim that
all upstream case-sensitivity defects are fixed.

## Rank-one array adapter

The adapter compares explicit bound expression trees, declaration rank/type/kind,
element subscripts, and exact declaration bindings. The pinned frontend reports
rank one on some scalar array-element occurrences. The adapter therefore verifies
scalar-element structure (one scalar integer subscript) and the declared element
type instead of relying on that incorrect occurrence-rank metadata. No producer
rank patch is applied. Deliberately inconsistent IR regressions exercise bounds,
rank, element binding and assignment-target checks.


## Whole-array shape validation in 0.4.0

Bare array references retain their declaration identity and rank/type/kind check.
The adapter independently derives every expression's rank and extent from symbol
bounds and child expressions. Unary operators preserve shape; binary operations
and the supported elemental intrinsics permit scalar expansion or equal array
extents. It memoizes the derivation and rejects cycles, excessive depth, invalid
caches, rank/extent disagreement, vector subscripts and array-valued scalar
contexts. Assignment targets are checked independently for conformability.

The pinned frontend's unreliable expression-rank inference is not used as a
substitute for this derivation. Its original AST still must structurally agree,
and its declaration metadata and bindings still must match. Unary plus, which
FortFront erases, is included in independent cache validation. Native regressions
cover a valid whole-array baseline and 20 deliberate disagreements. No new
vendored patch was needed for whole-array expressions.

## Section adapter extension (0.5.0)

FortFront represents rank-one sections with `array_slice_node`, whose base and
single `range_expression_node` are checked against the independent IR. The
adapter compares the base declaration identity/type/kind and each optional
lower, upper and stride tree, including the distinction between an omitted
operand and an explicit expression. Every range must match either a declaration
bound or a checked section; no extra executable ranges are silently accepted.
Section targets additionally check the instruction's symbol and section tree.

The independent shape walk marks sections as rank one with dynamic extent -1.
Elemental operations propagate dynamic shape, retaining known extents separately
so a dynamic child cannot conceal conflicting static operands. Scalar INTEGER
triplets, rank-zero contexts, exact cache agreement, cycles and section-target
metadata are validated before execution. All runtime descriptors are private;
no FortFront AST pointers reach the evaluator. No new vendored patch was needed.

The pinned `semantic_array_slice.infer_array_slice_type` resolves the slice base
but does not semantically visit calls inside range operands. Consequently an
array element such as `a(1)` in `a(a(1):a(2):a(3))` can retain a false
`is_array_access` occurrence flag. The adapter accommodates that missing flag
only while recursively matching a section triplet operand. It still requires the
exact name, a nonintrinsic call, one scalar INTEGER subscript, resolved rank-one
declaration identity and type/kind, and an exact subscript expression tree. The
ordinary element path still requires the flag. Native baseline and mutation
regressions cover nested element endpoints/strides and forged bindings,
subscript types, and values. This is an occurrence-metadata accommodation, not a
source rewrite or a bypass of FortFront's AST or binding checks.


See [module-function producer corrections](FRONTEND-MODULE-FIXES.md) for the
array-reference inference and procedure semicolon-boundary fixes in 0.6.0.

## Module/function adapter extension (0.6.0)

The independent IR now retains module identities, explicit function signatures,
USE associations, unique scoped symbols and instruction/expression ownership.
Function code precedes the main entry point; each procedure has a checked,
nonoverlapping instruction interval. Dummy arguments are ordered symbol IDs,
with a separate mutable RESULT symbol. No AST pointers enter the runtime.

The adapter maps the original FortFront module/function/program tree before
checking declarations and statements. It uses actual AST body membership to
map nested IF/DO statements, because some frontend parent links are absent.
Exact scoped declaration identities, dummy names/order/INTENT(IN), RESULT,
module membership and USE bindings are checked. Forward calls work because
all declaration identities are collected first. Type/kind/rank checks on actual
argument expression trees are combined with exact callee binding, rather than
trusting a success flag or treating module functions as elemental intrinsics.

A lexical intrinsic marker can remain set on a user function named COUNT or
SUM. For user calls only, the adapter resolves the name to a BINDING_FUNCTION
and requires the exact expected function-definition node. This is independent
of the unreliable lexical marker and cannot substitute a same-named function
from another module. Declaration type/kind and scalar signature checks remain.

The adapter checks procedure ranges, control transfers, call cycles, backing
storage and scoped ownership independently of parser caches. The new native
module test includes two baselines and 25 deliberate disagreements, covering
callee identity, argument/result metadata, type/rank, USE, scope, malformed
indices and missing backing storage. Prior frontend mutation suites remain.


## Numerical and subroutine adapter extension (0.7.0)

The original source still must pass FortFront STANDARD/STRICT with semantics
and no rewriting. Module PARAMETER declarations occupy separate module scopes.
The adapter compares module defaults, explicit PUBLIC/PRIVATE name lists,
declaration accessibility, main-program USE ONLY names and their order, and
exact function/subroutine declaration identities. Intrinsic ISO_FORTRAN_ENV
imports are a deliberately closed contract: explicit intrinsic USE with ONLY
REAL32/REAL64 introduces scalar INTEGER constants 4/8, with checked import
location, scope, attributes and values. No arbitrary synthetic source or
undeclared symbol is accepted.

Typed function results are matched to the actual function header node. PURE
prefixes, explicit RESULT names, scalar INTENT(IN) dummies, internal/main or
module ownership, and REAL kinds 4/8 are independently checked. Assumed-length
CHARACTER dummies are checked for LEN=* rather than interpreted as a kind.
Each real literal is decoded at its declared precision; suffix bindings and
kind propagation through arithmetic, intrinsic and user calls are checked.
Named-constant caches are recomputed with the declared kind, preserving REAL64
precision instead of comparing a mistakenly rounded REAL32 value.

CALL instructions must resolve to the exact subroutine node with matching
actual count, type, kind, scalar rank and expression trees. RETURN and ERROR
STOP require their actual AST nodes. Character stop messages, integer stop
expressions, and literal PRINT/WRITE format strings are matched exactly. The
call-cycle check includes both expression calls and CALL instructions. All
procedure intervals remain disjoint from main and one another.

The numerical adapter regression covers its baseline plus 29 deliberate IR
mutations, including kind caches, intrinsic imports, public/private state,
USE ONLY data, typed results, calls, output formats and stop/return statements.
The earlier hand-built scalar fixture now initializes its literal type tag,
as required by the stronger literal-cache check.

## Correction 4: scope-aware named REAL kinds and actual arguments

`vendor/patches/0004-scope-aware-real-kinds.patch` shares the existing kind
resolver with strict actual/dummy checking. The previous checker treated
`real(dp)` dummies as default REAL and the `d` in `_dp` as a double exponent.
It rejected the original Black-Scholes program with 20 false mismatches.
Scalar actual declarations and typed function results are now resolved in
scope before relying on incomplete inference metadata. This also handles
CHARACTER actuals forwarded by internal subroutines. True real32/real64
argument mismatches remain errors.

Named integer parameter initializers can resolve ISO_FORTRAN_ENV constants,
including renamed imports, through the existing intrinsic-module lookup path.
Thus `wp=real64` does not depend on recognizing the conventional spelling `dp`.
The original Black-Scholes source passes strict semantic validation, and all
18 REAL declaration/function-result metadata targets resolve to 64 bits.
This is a targeted fix within the existing frontend type model, not complete
Fortran kind or constant-expression support.

## Correction 5: complete IF grammar inside procedures

`vendor/patches/0005-procedure-complete-if-grammar.patch` changes procedure-body
IF dispatch to the existing complete IF parser used by main programs. The
previous token-slice helper selected the first ELSE/END IF without nesting,
while its inline fallback parsed only comparison expressions. As a result,
valid logical tails, inline ERROR STOP statements, nested branches and RETURN
statements could disappear from the original AST even when compilation
reported success. The adapter correctly rejected these incomplete trees.

The correction passes the original collected token slice and diagnostic sink
to the canonical parser. It does not change the user source, loosen errors or
replace AST checking with a success flag. The Black-Scholes original and the
numerical adapter fixture exercise logical inline IF, nested branches and
RETURN through the full strict frontend. Existing module/array/section adapter
regressions continue to run against this dispatch.

## Correction 6: exponent-only real literals and ERFC

`vendor/patches/0006-exponent-literals-and-erfc.patch` recognizes real literals
with E/D exponents but no decimal point, such as `1e-08_dp`. Classification
examines only the numeric portion, so letters inside an integer kind suffix
do not become exponent markers. ERFC is added to the intrinsic registry with
a REAL argument/result, using existing same-kind inference and annotation.
Main-program calls no longer produce a false missing-interface diagnostic.

`test/test_named_real_kind_frontend.f90` runs 21 strict frontend scenarios:
17 positive/negative direct-call cases, two internal CHARACTER/nested typed
function cases, module/host metadata, and ERFC metadata. It covers real32/64
mismatch rejection, named/numeric kinds, ISO kind aliases and renames,
shadowed `dp=4`, E/D exponents, and integer suffixes containing `d`. FPM discovers
this native test automatically; no semantic pass is bypassed. The independent
numerical corpus separately includes tiny-volatility and real64-intrinsic
programs that exposed these two gaps.

## Argument association (0.8.0)

Procedure declarations now retain explicit IN, OUT, or INOUT intent. Functions
remain IN-only. Rank-one dummy arrays use assumed shape, with an optional
constant lower bound; explicit-shape and assumed-size dummies remain rejected.
The adapter checks declared intent, rank, kind, lower-bound expressions, omitted
upper bounds, and the independently derived dynamic extent. Writable actuals
must be nonparenthesized variable, element, or section designators, and cannot
name PARAMETERs, IN dummies, or active DO variables. Scalar SIZE and dimensional
LBOUND/UBOUND calls have independently checked array and DIM argument shapes.

### Correction 7: array dummy argument types

`vendor/patches/0007-array-dummy-argument-types.patch` repairs the strict argument
checker's reconstruction of declared array types. Previously it retained only
the scalar base type, rejecting valid array actuals. The correction retains
one array layer per dimension and resolves identifier actual types from their
declarations, preserving REAL kind selection. Type matching remains strict;
no semantic pass is bypassed. Scalar array elements recover their declared
element kind; sections recover that kind and count AST triplets for their rank,
even before occurrence inference has run. REAL64 section and element regressions
cover numeric and named kinds in IN, OUT, and INOUT calls.
`test/test_argument_frontend.f90` checks the
accepted source and 15 independent AST/IR mutation rejections.

The pinned frontend may omit `is_array_access` on an assumed-shape dummy element
inside a subroutine body. For this specific declaration category, the adapter
checks the exact scoped declaration identity, declared rank/type/kind, and the
single scalar INTEGER subscript rather than requiring that occurrence flag.
All other array-reference checks remain active; ordinary array occurrences
retain the existing flag requirement outside section triplets.


## Rank-two cross-checks (0.9.0)

The adapter independently derives both dimension extents and their total, checks
constant bound trees and caches in both dimensions, and validates exact declaration
bindings and both scalar INTEGER subscript trees for rank-two element references.
Expression and assignment conformance checks compare every dimension, including
zero-total arrays. Assumed-shape dimensions remain dynamic and are checked at
runtime. Procedure locals may have constant explicit shapes. Native tests add
21 deliberate mismatches in second bounds, extents, indices, rank and bindings.

The pinned frontend sometimes omits identifier occurrence metadata in nested
DO bodies and the array-access flag on procedure-local element calls. For these
structural references the adapter resolves the exact declaration, verifies its
type/rank/kind, and checks the complete scalar subscript trees rather than treating
missing occurrence metadata as an alternative type. No new vendor patch is used.
Rank-two slice nodes remain outside the admitted source subset.

## Rank-two section extension (0.10.0)

The adapter now validates all source dimensions of a slice or call/subscript AST
node. Each dimension carries either one scalar INTEGER operand or an exact
three-operand triplet with independently checked omissions. Result rank equals
the triplet count; rank-two section dimension caches are dynamic. Scalar/triplet
classification, second-dimension operands and cached ranks are covered by native
mutation tests. The pinned FortFront sources and all existing patches are
unchanged for this extension. See RANK-TWO-SECTIONS.md for execution semantics.

## Keyword actual arguments (0.12.0)

Vendor patch 0008 marks assignment wrappers in expression-call argument lists as
keyword arguments, matching existing CALL parsing. The adapter independently
associates keyword names with checked signatures, matches RHS expressions, and
requires every skipped keyword wrapper to be accounted for by a supported call.
The producer regression exercises scalar/array RHS metadata and strict type
checking; the adapter regression tests source/IR association disagreements.

Vendor patch 0009 preserves the inferred result types of conversion intrinsics
when collecting call signatures, instead of replacing them with operand types.
It also preserves elemental conversion array shape/rank with the converted
element type. Direct strict producer tests cover nested INT/REAL scalar and array
actuals, DIM conversions and type mismatch rejection.

## PURE/SIMPLE prefixes (0.13.0)

The lexer, unit scanners and procedure prefix consumers retain SIMPLE as a
separate AST prefix. Existing producer pure-body/dummy classification recognizes
its implied purity. The interpreter IR stores effective purity, SIMPLE and the
explicit PURE spelling separately; its adapter compares all three against AST
prefixes, and independently enforces SIMPLE-only function/subroutine calls.
No source text is rewritten. The supported statement/declaration boundary still
rejects unknown stateful facilities conservatively. See [PURE-SIMPLE.md](PURE-SIMPLE.md)
and patch 0010. Standalone upstream-wide SIMPLE conformance is not claimed.

## Correction 11: pure ELEMENTAL function calls (0.14.0)

The pinned producer already recognizes ELEMENTAL and validates its scalar dummy
and result declarations. New direct probes exposed later inference/annotation
paths that collapsed array references to scalars, overrode declared result types
from actuals, or rejected array actuals against scalar dummies. Patch 0011 retains
scalar procedure signatures while lifting call-result shapes; its interface
lookup is scope-aware. Strict argument checking compares each actual's element
type for ELEMENTAL interfaces, and resolved metadata keeps the call rank plus
the declared result kind. Later scalar-result propagation no longer overwrites
these calls. See [the exact patch and limitations](../vendor/patches/0011-elemental-call-types.md).

The independent recognizer retains ELEMENTAL, explicit PURE and effective purity
separately. It enforces scalar INTENT(IN) dummies/results, exact types/kinds and
static conformability. The adapter independently derives call shapes, compares
the source designation and bindings, and requires ELEMENTAL call-site resolved
type/rank/kind to match. Runtime checks cover dynamic sections/assumed shapes.
At 0.14.0, ELEMENTAL subroutines and IMPURE procedures remained outside
interpreter admission; correction 12 and the 0.15.0 interpreter extend that scope.


## Correction 12: ELEMENTAL subroutine CALLs (0.15.0)

The structural CALL-signature checker used a second strict-argument validation
route without forwarding the declaration's ELEMENTAL flag. Valid array actuals
were therefore rejected against scalar dummies, despite the dedicated strict
checker already handling element-type association. Patch 0012 forwards the
preserved prefix to the existing validator. It does not disable type checks:
an array of REAL still cannot associate with an INTEGER elemental dummy.
See [the patch note](../vendor/patches/0012-elemental-subroutine-calls.md).

The recognizer and adapter independently verify IMPURE/ELEMENTAL/PURE/SIMPLE
prefixes, scalar dummy declarations, exact binding and keyword association,
conformability, and OUT/INOUT actual rank/definability. Runtime validation repeats
invariants for descriptors, actual-symbol type/kind/rank, dummy intent, empty
calls, complete-call overlap and shared budgets. The interpreter, not FortFront
or GNU, supplies ordered scalar frames, definition flags, and cached impure
function results. See [the execution contract](ELEMENTAL-SUBROUTINES.md).

## Corrections 13–14: constructors and KIND inquiries (0.16.0)

Patch 0013 avoids speculative implied-do parsing for a nested legacy `(/.../)`
constructor. The old speculative path left an incomplete binary node in the
arena even when the subsequent constructor parse succeeded. The adapter still
rejects incomplete AST nodes; the producer now creates a valid tree instead.
See [the constructor patch note](../vendor/patches/0013-nested-legacy-constructors.md).

Patch 0014 retains the value expression of declaration KIND selectors, links
that expression to its declaration scope, and computes KIND from type metadata
rather than argument data. Strict dummy metadata uses the same retained selector
AST for direct KIND declarations, retaining REAL32/REAL64 mismatch rejection.
Homogeneous untyped constructors retain exact element
kind metadata. See [the KIND patch note](../vendor/patches/0014-kind-inquiry-selectors.md).

The independent adapter matches constructor elements and derives concatenated
rank-one extents, enforcing homogeneous numeric/logical types and REAL kinds.
It verifies declaration constant-expression trees and assignment conformance.
KIND results are scalar INTEGER even for array arguments. Explicit REAL
selector expression trees are independently matched as well as declaration
metadata. For a module PARAMETER selector where the public binding query misses
an attribute-level PUBLIC declaration under a PRIVATE default, the adapter uses
the already verified USE/visibility mapping and requires the exact declaration
binding in that originating module. Typed function header selectors retain the
existing metadata check and literal/named-constant grammar.

RANDOM_NUMBER is matched as an intrinsic CALL with one positional or HARVEST
actual. The adapter independently rejects non-REAL, nonwritable, parenthesized,
read-only, and PURE/SIMPLE uses, and checks the exact variable/element/section
binding and rank. The interpreter alone supplies random values.


## 0.17.0 adapter additions

The bounded adapter now also cross-validates SELECT CASE selectors, bounds and
branch structure; scalar CHARACTER lengths and numeric/logical array PARAMETER
caches; INTEGER kind metadata; module TYPE definitions, components, constructors
and operator interfaces; function-name results; internal WRITE; and normal STOP.
Operator identity includes operand kinds and USE ONLY visibility. Cached integer
values retain kind identity, not merely numeric equality.

Patch 0015 preserves nested SELECT parsing inside CASE and DO bodies. Patch 0016
repairs derived constructor resolution, TYPE/interface visibility and physical
TYPE source positions. Patch 0017 retains physical source-line metadata through
continued statements, including IF/STOP. All are incremental, replayable changes
to the same pinned FortFront source. See the patch notes and the feature contracts
[DERIVED-TYPES.md](DERIVED-TYPES.md), [SELECT-CASE.md](SELECT-CASE.md) and
[INTEGER-KINDS.md](INTEGER-KINDS.md). Older feature-specific reports describe the
subset at the time of those releases.

Patch 0018 shares the canonical declaration-resolved expression type query with
strict actual/dummy checking. This fixes the reported REAL64 `mean(x**2)` call,
keeps scalar array-element ranks distinct from array expressions, and preserves
INTEGER/REAL kind promotion for exponent expressions. It does not skip call verification
or permit mismatched kinds/ranks. See `tests/array_expression_arguments` and
`vendor/patches/0018-array-expression-actual-types.md`.

Patch 0019 recognizes accessible USE-associated array declarations when the semantic scope cache omits them, preserving private/ONLY and scalar/procedure checks. Patch 0020 parses the full logical precedence ladder in scalar/array declaration initializers instead of truncating their AND/OR/EQV/NEQV tails. Both retain independent adapter verification; regression suites cover exact wide INTEGER values, binding visibility, malformed tails, and producer/adapter mutations.

## Version 0.18.0 CHARACTER, generic and CLASS support

The adapter now independently validates CHARACTER lengths/constructors and
concatenation, scoped named generic declarations and per-call specific selection,
CLASS spelling and type identity, type-bound receiver/argument association, and
defined-output callback signatures and child-write controls. The runtime executes
only the private IR and captures child output within the bounded parent record.

New producer corrections remain narrow and replayable: patch 0021 preserves empty
typed legacy constructors; 0022 recognizes actual scoped generic explicit
interfaces; 0023 preserves CLASS and defined-output bindings and resolves type
identity in its true module scope; 0024 resolves generic result type/kind/rank at
each call occurrence, including ELEMENTAL REAL64 array expressions. No adapter
result-type check is disabled. Patch 0023 is based on the tree after 0021–0022,
and 0024 follows it. The feature guides describe supported limits:
[CHARACTER arrays](CHARACTER-ARRAYS.md), [generics](GENERIC-PROCEDURES.md), and
[CLASS/type-bound calls](CLASS-TYPE-BOUND.md).

## Version 0.19.0 kind inquiries

Patch 0025 registers SELECTED_REAL_KIND and resolves P/R/RADIX keyword slots
for declaration kind metadata. The interpreter independently checks the argument
association and executes its explicitly bounded REAL32/REAL64 model. The producer
knows wider kinds, which remain outside the interpreter's supported storage kinds.
See [the feature contract](UTILITIES.md) and
`vendor/patches/0025-selected-real-kind.md`. The source-cap increase changes no
producer source, and all parser/AST agreement checks remain enabled.


## Version 0.20.0 integrated language increment

Patches 0026, 0027, 0029 and 0030 retain complete ELSE IF branches and parent
links, enforce defined-operator precedence and resolved result metadata, register
and infer ALL/ANY/COUNT/MERGE/DBLE, and preserve chained module PARAMETER
declarators. Number 0028 is intentionally unused: OPTIONAL/PRESENT required
interpreter/adapter changes, not a producer patch. Each shipped patch has a
provenance note and is replayed in numeric order against the 0.19 vendor tree.

The adapter independently reconstructs scoped USE associations, defined-operator
selection, optional actual slots and presence declarations, counted-loop transfer
targets and intrinsic keyword masks. User-procedure omitted arguments remain
explicit zero slots; intrinsic optional keyword slots use separate mask metadata.
Do not compact user optional slots or bypass strict producer validation.

Feature contracts and remaining boundaries are in CONTROL-FLOW.md,
DEFINED-OPERATORS.md, OPTIONAL-ARGUMENTS.md, LOGICAL-INTRINSICS.md and MODULE-USE.md.

## 0.21 automatic arrays, array results and hyperbolic metadata

The adapter independently checks automatic-bound expression structure and identifier
bindings rather than accepting cached fixed extents. Ordinary array function
results retain declaration-derived rank/type/kind and acquire extents from each
completed invocation. Vendor patch 0033 corrects standard-syntax recursion metadata
that affected bodies assigning function-name array results; recursion remains
unsupported. Patch 0032 registers SINH/COSH/TANH and preserves REAL kind/rank
through producer inquiries. No semantic validation pass is bypassed. Both patches
are retained with attribution and replayed with fuzz zero against the 0.20 tree.

## 0.22 metadata capacity, COUNT bounds and transformations

The enlarged symbol/procedure/generic/accessibility tables use checked heap
storage. Parser call-graph analysis uses a sparse adjacency list and iterative
walk; the independent adapter continues to validate source bindings and cycles.
COUNT specification expressions are checked structurally in both paths and read
entry-associated mask values only during bounded runtime evaluation.

PACK and RESHAPE receive independent keyword association, argument and result
type/kind/rank/CHARACTER checks. PACK freezes selection and caches owned results;
RESHAPE freezes shape/order and maps result elements to SOURCE/PAD. Direct IR
entry points repeat structural and metadata checks, including unevaluated KIND.
No additional vendor patch was needed. All 457 vendored files and existing
patches are byte-for-byte identical to 0.21.0; no validation pass is bypassed.
See METADATA-LIMITS.md, AUTOMATIC-ARRAYS.md, PACK.md and RESHAPE.md.

## Mutable module declaration accessibility

Vendor patch 0034 makes the scoped resolver honor PUBLIC/PRIVATE attributes on
intrinsic declarations, including multi-declarators. It fixes both public exports
under PRIVATE defaults and private exclusions under PUBLIC defaults. The normal
semantic checks and exact adapter declaration-identity checks remain enabled.
See [the patch note](../vendor/patches/0034-module-declaration-accessibility.md).

## Location intrinsic metadata

Vendor patch 0035 reports MINLOC/MAXLOC result type, kind and rank independently
of the source array type, including DIM reductions. It preserves validation and
source representation. See [the patch note](../vendor/patches/0035-location-intrinsics.md).

## Numeric allocatable arrays

The source guard and adapter independently validate numeric rank-one/two
ALLOCATABLE declarations and deferred dimensions, ALLOCATE/DEALLOCATE target
identity, explicit lower/upper bounds and a writable local scalar INTEGER STAT.
ALLOCATED validates a whole allocatable variable without reading its elements.
Vendor patch 0036 links allocation statement children to their owners, restoring
scope resolution for imported module arrays and DEALLOCATE. The runtime keeps
allocation status separate from element-defined flags and rejects unallocated
uses before accessing storage. See [ALLOCATABLES.md](ALLOCATABLES.md).

FortFront option `allow_allocatable_reallocation` is default-off; the interpreter
explicitly enables it while retaining strict semantic/declaration validation.
Vendor patch 0037 carries this setting through semantic context initialization,
copy and clone paths and gates only the old automatic-reallocation prohibition.
The native option test verifies unchanged default rejection, opt-in acceptance
and continued rejection of undeclared variables.

## Inferred-length CHARACTER parameters

The recognizer resolves each inferred PARAMETER length independently; the adapter
recomputes it from the initializer and checks cached values. Vendor patch 0038
registers CHAR/ACHAR, preserves their CHARACTER kind and elemental rank in public
metadata, and keeps declaration lookahead scanning through nested initializer
keywords. Strict semantic validation remains enabled. See
[CHARACTER-PARAMETERS.md](CHARACTER-PARAMETERS.md).

## CHARACTER procedure descriptors

Vendor patch 0039 retains complete CHARACTER length-expression token text, derives
canonical type/rank for concatenations and array function results, and carries
assumed-length dummy markers through strict actual checking. Fixed-length array
matching, type/kind/rank checks and all independent adapter validation remain
active. See [CHARACTER-PROCEDURES.md](CHARACTER-PROCEDURES.md) and the replayable
patch explanation for scope and attribution.

## Rounding and base-ten logarithm

Vendor patch 0042 registers LOG10 and preserves its REAL kind/rank. It resolves
NINT/FLOOR/CEILING as elemental INTEGER results, including KIND supplied before
A by keyword. The recognizer, independent adapter and runtime all verify the
REAL input, scalar constant result KIND and retained shape. Empty arrays and
unevaluated KIND inquiries still reject malformed metadata. Strict frontend
semantic checks remain enabled. See [ROUNDING-INTRINSICS.md](ROUNDING-INTRINSICS.md).

## Allocatable CHARACTER descriptors

Vendor patch 0040 represents deferred CHARACTER dummy lengths as dynamic in the
strict type matcher. The adapter independently checks exact `:` declaration text,
actual/dummy deferred-length agreement and typed ALLOCATE length-expression text.
The runtime carries length separately from storage and initialized-element flags.
See [ALLOCATABLE-CHARACTER.md](ALLOCATABLE-CHARACTER.md).

## FORALL metadata

Vendor patch 0041 retains complete one/two-index headers, optional masks and
assignment-only construct bodies through main programs and procedures. It fixes
end-of-header scanning, declaration lookahead, physical parent links and integer
control-flow inference without disabling strict semantics. The independent
recognizer and adapter validate the retained structure before the runtime
performs snapshot assignment. See [FORALL.md](FORALL.md).

## OPTIONAL CHARACTER declaration metadata

Vendor patch 0043 preserves CHARACTER length tokens for grouped declarations,
including the single-entity path selected by OPTIONAL before INTENT. The adapter
checks these tokens and OPTIONAL against guarded IR independently. Producer
regressions cover both attribute orders and grouped fixed/assumed-length scalar
dummies; adapter/runtime mutations cover scalar, array and allocatable forms.

## Scalar substring and CHARACTER intrinsic metadata

Patch 0044 keeps scalar CHARACTER slice rank zero before semantic substring
flag inference and preserves grouped module declaration length tokens. The
adapter independently checks base identity, bounds, result length and rank.
Patch 0045 derives INDEX/LEN_TRIM INTEGER kind and elemental rank, and
ADJUSTL/ADJUSTR CHARACTER result metadata from the producer's argument nodes.
No unsupported syntax or adapter disagreement is bypassed. Dedicated producer
tests and independent malformed AST/IR regressions accompany both features.

Patch 0046 keeps explicit array declarations ahead of same-named intrinsic
classification, so INDEX/LEN_TRIM/ADJUSTL/ADJUSTR can be ordinary source names.
The canonical producer updates both intrinsic and array-access flags; the
adapter retains strict name, declaration-identity, type and rank comparisons.

## WHERE construct metadata

Vendor patch 0047 registers WHERE in nested IF/DO/SELECT statement dispatch,
retains complete WHERE bodies inside procedures, recognizes ENDWHERE, and
preserves physical source positions after continued headers. The adapter
independently checks the first mask, ELSEWHERE mask presence/order, body
assignment identity, parent scope, arm intervals and final target. Strict
frontend semantic checks remain enabled. See [WHERE.md](WHERE.md).

## SCAN/VERIFY metadata

Vendor patch 0048 registers SCAN and VERIFY and derives their INTEGER result kind, elemental rank and shape from source arguments, including BACK and KIND keywords. Bound ordinary arrays named like intrinsic procedures keep declaration precedence. The interpreter adapter and runtime independently revalidate the descriptor.

## INTENT continuation and SHAPE metadata

Patch 0049 canonicalizes the complete INTENT attribute, preserves logical-line origins across retained comment trivia, and stops statement slicing at the correct logical newline. The interpreter recognizes both INOUT and IN OUT; declaration identity and direction remain independently checked. Patch 0050 derives SHAPE's rank-one INTEGER result, result kind, and extent from the SOURCE rank. Direct producer, adapter and runtime corruption tests cover both changes; neither removes strict adapter checks.

## FINDLOC metadata

Vendor patch 0051 registers FINDLOC and retains its scalar VALUE slot while deriving rank-one no-DIM or rank-reduced DIM results from ARRAY metadata. Semantic and standardizer recognition preserve the FINDLOC call. Adapter/runtime validation independently checks positional/keyword binding, rank, type, kind, MASK, BACK and DIM. See [FINDLOC.md](FINDLOC.md) for the bounded contract and remaining producer limitation.

## Literal substring source preservation

Vendor patch 0052 retains literal substring bases and range ASTs, including
constant bounds, for independent adapter validation. Runtime validation does not
trust that match. See [LITERAL-SUBSTRINGS.md](LITERAL-SUBSTRINGS.md).

## Quoted operator token kinds

The guarded expression parser requires operator-kind tokens before unary or
binary dispatch. Quoted spellings remain CHARACTER data. This repairs the exact
negative-prefix line in original str_int without changing its body. The later
0.43 token-kind correction also promotes quoted delimiter literals and rejects
quoted pseudo-delimiters; see [PUNCTUATION-LITERALS.md](PUNCTUATION-LITERALS.md). See
[QUOTED-OPERATORS.md](QUOTED-OPERATORS.md).

## Contextual PROCEDURE names

Vendor patch 0056 preserves PROCEDURE in declaration entity, dummy, imported
entity and module-specific name positions while leaving actual keyword clauses
unchanged. Independent source and binding validation remain active; see
[PROCEDURE-IDENTIFIERS.md](PROCEDURE-IDENTIFIERS.md).

## Contextual CHAR names

CHAR is resolved through declarations before falling back to its intrinsic form.
The source guard no longer reserves this spelling in all name positions. The
adapter independently rejects intrinsic CHAR nodes when the source scope binds
CHAR to a data object, function or generic; producer and runtime are unchanged.
See [CHAR-IDENTIFIERS.md](CHAR-IDENTIFIERS.md) for scope, original utility provenance
and retained boundaries.

## Numeric vector, matrix and tensor gathering

Vendor patch0059 preserves continued inline-IF action source lines and vector-selector
result dimensions. Independent adapter matching validates the exact numeric rank-two
base, first-axis INTEGER vector and bare full-column colon. In 0.50 rank-three
numeric bases support exactly one INTEGER vector on any axis, with bare colons
on the others. Source identity and all selector/type/kind/rank caches remain
independently checked by the adapter and runtime, including KIND and empty
expression contexts. See [ROW-GATHER.md](ROW-GATHER.md) for scope and original-source evidence.

## ISNAN GNU extension

Vendor patch0062 registers ISNAN and preserves its elemental default-LOGICAL
metadata. Independent source-binding checks distinguish it from a declared
object, function or generic of the same spelling. Runtime count/type/kind/shape
validation remains independent, including KIND and empty-expression paths. See
[ISNAN.md](ISNAN.md) for the explicit GNU-extension and finite-value boundaries.

## Intrinsic ISO environment alias validation (0.38)

The closed intrinsic USE contract now includes REAL32/REAL64 and INT32/INT64
local ONLY aliases, plus the unsupported-kind sentinel REAL128=-1. The adapter
compares the exact local and remote names; runtime validates immutable import
metadata even on unused and KIND paths. See [ISO aliases](ISO-FORTRAN-ENV-ALIASES.md).
Ordinary module USE renaming and actual REAL(16) values remain unsupported.

## ERFC_SCALED

Vendor patch 0064 supplies REAL kind and elemental-rank metadata. The adapter
independently validates the source binding and operand/result contract; runtime
validation also covers KIND and empty expressions. The stable finite numerical
implementation and independent accuracy corpus are described in
[ERFC-SCALED.md](ERFC-SCALED.md).

## CSHIFT ARRAY metadata

Vendor patch0066 registers standard CSHIFT and preserves type, kind and rank from
ARRAY rather than SHIFT or DIM, including reordered keyword calls. Ordinary
source declarations and procedure/generic bindings remain authoritative. The
adapter independently validates exact argument association, result shape and
source identity; runtime independently validates descriptors, shift conformance,
DIM, temporary limits and values. See [CSHIFT.md](CSHIFT.md).

ERF/Bessel producer metadata is pinned by patch0068. Elemental rank is merged
independently; REAL result kind follows X even when INTEGER8 N precedes REAL4 X or
keywords are reordered. Adapter source bindings and count/type/kind/shape checks
remain independent. KIND/empty paths validate metadata without evaluating values.
The bounded numerical contract and unchanged-source proofs are in
[ERF-BESSEL.md](ERF-BESSEL.md).

## 0.39 metadata extensions

Patches0067–0069 add source-derived metadata for real rounding/inverse hyperbolics,
ERF/Bessel elemental calls and scalar exponent-model inquiries. The canonical
producer retains source binding precedence; the independent interpreter adapter
and runtime enforce the narrower documented domains, kinds, argument grammar
and resource limits. Cumulative replay against certified0.38 reproduces all457
vendored files, with104 unique registered names. See the feature contracts and
`VERIFICATION.md` for separate source, mutation and mathematical evidence.

## Literal unlimited formats and G0

The shared bounded format validator accepts a final outer `*(...)` group and
bare intrinsic-type `G0`. Existing exact-source literal binding, independent
adapter checks and runtime revalidation remain in force; malformed direct IR
formats are rejected. No vendor producer correction is required. See
[UNLIMITED-FORMATS.md](UNLIMITED-FORMATS.md) for the contract and limits.


### Version 0.40 producer ledger

Patches 0070–0073 are cumulative after 0069. The final registry has 106 unique names: DPROD and TAND are new; ACOS was already present and only its metadata is corrected. REAL(A) has default REAL kind4, with constant selected KIND handled separately. Multi-object allocation retains source order and independently verified group descriptors; contextual STAT names remain data objects unless followed by `=`.

## Named CHARACTER PARAMETER output formats

The canonical producer retains a simple format name. The adapter independently
resolves its source declaration and verifies scalar CHARACTER PARAMETER state,
initializer/cache agreement, declared length and the exact lowered format bytes.
Literal source comparison now explicitly includes length. No vendor correction
is needed. Runtime format validation and output staging are unchanged; see
[NAMED-FORMATS.md](NAMED-FORMATS.md).

## Defined CHARACTER plus producer metadata

Patch 0077 preserves source CHARACTER `+` in STANDARD mode and resolves a visible
operator specific's declared result. It also permits named-generic omission only
of source-declared OPTIONAL dummies, needed by the unchanged `str(i)` dependency.
Defined-operator operands remain required; numeric addition and lazy convenience
concatenation retain their prior paths. The registry is unchanged. See
[CHARACTER-PLUS.md](CHARACTER-PLUS.md) for independent validation and limits.

## Internal READ producer metadata

Patch 0080 sets the existing formatted flag in the generic READ factory. The
adapter independently checks exact UNIT, IOSTAT and target expression bindings,
control count/order, literal list format, and shared IR validation. Producer
support for broader READ syntax is not interpreter permission to execute it.

## Runtime format and ADVANCE metadata

Patch 0082 sets the generic WRITE factory's existing formatted flag, without
registry or type-query changes. The adapter separately verifies whole scalar
CHARACTER format identity and exact UNIT/FMT/ADVANCE controls; the runtime
revalidates descriptors and stages each output statement before commitment.
See [RUNTIME-FORMATS.md](RUNTIME-FORMATS.md) for the bounded syntax and record rules.

## Derived component defaults and anonymous main

Patch 0097 keeps module-leading sources on the ordinary unit/statement scanner,
retaining declaration trailing-token rejection in STANDARD and LAZY modes. The
adapter independently matches component initializer presence and constant roots
after module PARAMETER declaration identities are mapped. Empty positional
constructors and omitted trailing defaults retain exact source/type binding.
See [DERIVED-DEFAULTS.md](DERIVED-DEFAULTS.md) for lifetime and oracle boundaries.

## 0.50 producer corrections

Patches 0108–0110 retain completed DO-body parent links, canonical MASKL/MASKR/SHIFTR metadata and semicolon-separated CASE actions respectively. Independent source ownership and adapter checks are not relaxed. MASKL/MASKR default to result kind4; SHIFTR follows I rather than SHIFT. Those 0.50 patches did not add DO WHILE interpreter support or general CASE continuation-location remapping. The continued CASE-header fixture remains a GNU-valid, explicitly retained adapter boundary. See [element files](INTERNAL_WRITE_ELEMENT.md), [integer masks](INTEGER-MASKS.md) and [numeric gathers](ROW-GATHER.md).


## Bounded DO WHILE producer integration

Patches 0111–0113 preserve WHILE-name dispatch, complete nested/named anonymous-main DO slices and SELECT parent-stream ownership. The independent adapter checks condition, control form, names and body mapping; runtime rechecks scalar default LOGICAL metadata, cached payload agreement, cycles and control identity before evaluating the condition afresh. Existing effects and shared execution budgets remain. See [DO-WHILE.md](DO-WHILE.md). DO CONCURRENT, labeled termination and general CASE continuation-location remapping are not added.

## CHARACTER gather and actual-source marker validation

The bounded rank-one default-CHARACTER gather independently checks its base
binding/kind, rank, selector, unused fields and cached length in source matching
and runtime validation, including empty and KIND paths. Selected payloads are
checked before copying, and each cached string charge is released with its cache.
The separate [CHARACTER contract](CHARACTER-GATHER.md) records retained limits.

For [bare CHARACTER actuals](BARE_CHARACTER_GATHER_ACTUAL.md), parser, adapter and
runtime restrict admission to ordinary non-TARGET assumed-shape INTENT(IN)
dummies. The runtime retains whole-base identity for conservative writable and
host/USE alias checks; parenthesized actuals retain snapshot semantics.
The adapter verifies that grouping marker from independent producer tokens, not
the guarded IR. Written argument order is reconciled with keyword/formal order;
comments and CHARACTER literals cannot act as delimiter tokens. CALL nodes use
their statement/callee location, while function nodes use their closing-token
location and recover the corresponding opener by backward delimiter balance.
The early forward-only function-anchor assumption and its failing source/native
observations are retained in the focused evidence, not treated as passing proof.

## numeric rank-one and TRAILZ ownership

Rank-one INTEGER/REAL(4/8) gathers reuse independently validated base, selector, type/kind, shape and snapshot metadata. Bare association is admitted only for ordinary matching assumed-shape INTENT(IN); the independent CALL/function grouping-token check remains in force. Whole-base writable/host alias guards and external-effect restrictions are unchanged. See [numeric gathering](NUMERIC-VECTOR-GATHER.md).

The separate [TRAILZ/ISO contract](TRAILZ-ISO-INTEGER-AVAILABILITY.md) retains default-INTEGER elemental result metadata and distinguishes availability sentinels from supported small kinds. The indexed-import producer path distinguishes array data from procedure calls and preserves scalar-element versus array-section shape. The adapter checks owning USE, local/remote identity and written subscripts independently. This contract text does not assert final native or release certification, or broaden module re-export.
